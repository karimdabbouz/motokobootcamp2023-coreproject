import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

import Types "types";


actor {

    // ///////////////
    // IMPORT CANISTERS
    // //////////////

    let mbtCanister = actor "db3eq-6iaaa-aaaah-abz6a-cai" : actor {
        icrc1_balance_of : ({owner: Principal; subaccount: ?[Nat8]}) -> async Nat;
        icrc1_transfer : ({to: {owner: Principal; subaccount: ?[Nat8]}; fee: ?Nat; memo: ?[Nat8]; from_subaccount: ?[Nat8]; created_at_time: ?[Nat64]; amount: Nat}) -> async ({#ok: Nat; #err: {#GenericError: {message: Text; error_code:Nat}; #TemporarilyUnavailable; #BadBurn: {min_burn_amount: Nat}; #Duplicate: {duplicate_of: Nat}; #BadFee: {expected_fee: Nat}; #CreatedInFuture: {ledger_time: Nat64}; #TooOld; #InsufficientFunds: {balance: Nat}}});
    };

    let webpageCanister = actor "xwhzs-hiaaa-aaaak-aeaba-cai" : actor {
        addArticleSource : (?Text) -> async ({#ok: Text; #err: Text});
        removeArticleSource : (?Nat) -> async ({#ok: Text; #err: Text});
        updateArticleSource : (?Nat, ?Text) -> async ({#ok: Text; #err: Text});
    };


    // //////////////
    // STATE
    // //////////////
    /*
    - proposalDB: stores the proposals
    - proposalUsersDB: stores list of users who already voted for a given proposal
    */

    // Counters
    private stable var proposalID = 0;
    private stable var neuronID = 0;

    // Heap memory to stable memory
    stable var proposalDBStable : [(Types.ProposalID, Types.Proposal)] = [];
    stable var proposalUsersDBStable : [(Types.ProposalID, [Types.UserID])] = [];
    stable var neuronDBStable : [(Types.NeuronID, Types.Neuron)] = [];

    // Helper to go from stable to TrieMap containing non-stable type Buffer
    private func instantiateRelations() : TrieMap.TrieMap<Types.ProposalID, Buffer.Buffer<Types.UserID>> {
        let relation = TrieMap.TrieMap<Types.ProposalID, Buffer.Buffer<Types.UserID>>(Nat.equal, Hash.hash);
        for (val in proposalUsersDBStable.vals()) {
            let buf = Buffer.Buffer<Types.UserID>(0);
            for (user in val.1.vals()) {
                buf.add(user);
            };
            relation.put(val.0, buf);
        };
        return relation;
    };

    let proposalDB = TrieMap.fromEntries<Types.ProposalID, Types.Proposal>(proposalDBStable.vals(), Nat.equal, Hash.hash);
    let neuronDB = TrieMap.fromEntries<Types.NeuronID, Types.Neuron>(neuronDBStable.vals(), Nat.equal, Hash.hash);
    let proposalUsersDB : TrieMap.TrieMap<Types.ProposalID, Buffer.Buffer<Types.UserID>> = instantiateRelations();

    system func preupgrade() {
        let interimDB = TrieMap.TrieMap<Types.ProposalID, [Types.UserID]>(Nat.equal, Hash.hash);
        for (entry in proposalUsersDB.entries()) { // need to loop over entries to make the value (Buffer) a stable array
            interimDB.put(entry.0, entry.1.toArray());
        };
        proposalUsersDBStable := Iter.toArray(interimDB.entries());
        proposalDBStable := Iter.toArray(proposalDB.entries());
        neuronDBStable := Iter.toArray(neuronDB.entries());
    };

    system func postupgrade() {
        proposalDBStable := [];
        proposalUsersDBStable := [];
        neuronDBStable := [];
    };


    // /////////////
    // PUBLIC FUNCTIONS
    // /////////////


    // submit_proposal
    public shared(msg) func submit_proposal(action : {#addSource; #updateSource; #removeSource}, headline : Text, body : Text, sourceID : ?Nat, change: ?Text) : async Text {
        assert (msg.caller != Principal.fromText("2vxsx-fae"));
        let newProposal : Types.Proposal = {
            id = proposalID;
            sourceID = sourceID;
            creator = msg.caller;
            timestamp = Time.now();
            action = action;
            status = #active;
            headline = headline;
            body = body;
            desiredChange = change;
            votesPro = 0;
            votesCon = 0;
        };
        proposalDB.put(proposalID, newProposal);
        proposalID += 1;
        return "proposal submitted.";
    };


    // get_all_proposals
    public query func get_all_proposals() : async [(Types.ProposalID, Types.Proposal)]  {
        let result : [(Types.ProposalID, Types.Proposal)] = Iter.toArray<(Types.ProposalID, Types.Proposal)>(proposalDB.entries());
        return result;
    };


    // vote
    public shared(msg) func vote(proposalID : Types.ProposalID, vote : {#pro; #con}) : async Result.Result<Text, Text> {
        // Unwrap list of voters of this proposal and return error if user has already given her vote
        let voters = switch (proposalUsersDB.get(proposalID)) {
            case (null) {Buffer.Buffer<Types.UserID>(0)};
            case (?found) {
                found
            };
        };
        if (Buffer.contains<Types.UserID>(voters, msg.caller, Principal.equal) == true) {
            return #err("you have already voted on this proposal.");
        };
        let balance = await mbtCanister.icrc1_balance_of({owner = msg.caller; subaccount = null});
        assert (balance >= 100000000);
        let votingPower = balance / 100000000; // voting power == num of tokens
        let proposal = proposalDB.get(proposalID);
        var proposalData = switch (proposal) {
            case (null) {return #err("proposal not found.")};
            case (?proposalFound) {
                {
                    id = proposalFound.id;
                    sourceID = proposalFound.sourceID;
                    creator = proposalFound.creator;
                    timestamp = proposalFound.timestamp;
                    action = proposalFound.action;
                    status = proposalFound.status;
                    headline = proposalFound.headline;
                    body = proposalFound.body;
                    desiredChange = proposalFound.desiredChange;
                    votesPro = proposalFound.votesPro;
                    votesCon = proposalFound.votesCon;
                };
            };
        };
        switch (vote) {
            case (#pro) {
                if (proposalData.votesPro + votingPower >= 100) { // proposal passed when this vote is added
                    proposalData := {
                        id = proposalData.id;
                        sourceID = proposalData.sourceID;
                        creator = proposalData.creator;
                        timestamp = proposalData.timestamp;
                        action = proposalData.action;
                        status = #passed;
                        headline = proposalData.headline;
                        body = proposalData.body;
                        desiredChange = proposalData.desiredChange;
                        votesPro = proposalData.votesPro + votingPower;
                        votesCon = proposalData.votesCon;
                    };
                    proposalDB.put(proposalID, proposalData);
                } else { // proposal not passed yet
                    proposalData := {
                        id = proposalData.id;
                        sourceID = proposalData.sourceID;
                        creator = proposalData.creator;
                        timestamp = proposalData.timestamp;
                        action = proposalData.action;
                        status = proposalData.status;
                        headline = proposalData.headline;
                        body = proposalData.body;
                        desiredChange = proposalData.desiredChange;
                        votesPro = proposalData.votesPro + votingPower;
                        votesCon = proposalData.votesCon;
                    };
                    proposalDB.put(proposalID, proposalData);
                };
            };
            case (#con) {
                if (proposalData.votesCon + votingPower >= 100) { // proposal declined when this vote is added
                    proposalData := {
                        id = proposalData.id;
                        sourceID = proposalData.sourceID;
                        creator = proposalData.creator;
                        timestamp = proposalData.timestamp;
                        action = proposalData.action;
                        status = #declined;
                        headline = proposalData.headline;
                        body = proposalData.body;
                        desiredChange = proposalData.desiredChange;
                        votesPro = proposalData.votesPro;
                        votesCon = proposalData.votesCon + votingPower;
                    };
                    proposalDB.put(proposalID, proposalData);
                } else { // proposal not yet declined
                    proposalData := {
                        id = proposalData.id;
                        sourceID = proposalData.sourceID;
                        creator = proposalData.creator;
                        timestamp = proposalData.timestamp;
                        action = proposalData.action;
                        status = proposalData.status;
                        headline = proposalData.headline;
                        body = proposalData.body;
                        desiredChange = proposalData.desiredChange;
                        votesPro = proposalData.votesPro;
                        votesCon = proposalData.votesCon + votingPower;
                    };
                    proposalDB.put(proposalID, proposalData);
                };
            };
        };
        voters.add(msg.caller);
        proposalUsersDB.put(proposalID, voters);
        switch (proposalData.status) {
            case (#passed) {
                switch (proposalData.action) {
                    case (#addSource) {
                        let response = await webpageCanister.addArticleSource(proposalData.desiredChange);
                        return #ok("proposal passed. adding new source.")
                    };
                    case (#removeSource) {
                        let response = await webpageCanister.removeArticleSource(proposalData.sourceID);
                        return #ok("proposal passed. removing source.")
                        };
                    case (#updateSource) {
                        let response = await webpageCanister.updateArticleSource(proposalData.sourceID, proposalData.desiredChange);
                        return #ok("proposal passed. updating source.")
                        };
                };
            };
            case (#declined) {return #ok("proposal declined. no action to be taken.")};
            case (_) {return #ok("vote has been counted. no decision has been made yet.")};
        };
    };

};
