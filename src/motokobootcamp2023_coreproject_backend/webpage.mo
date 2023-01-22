import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Char "mo:base/Char";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

import Types "types";


shared(init_msg) actor class Webpage() {

    let owner = init_msg.caller;


    // ////////////
    // STATE
    // ////////////
    /*
    - articleSourceDB: stores sources to hypothetical articles in a wiki or news publication
    */


    // Counters
    private stable var articleSourceID = 0;

    // Heap memory to stable memory
    stable var articleSourceDBStable : [(Types.ArticleSourceID, Types.ArticleSource)] = [];

    let articleSourceDB = TrieMap.fromEntries<Types.ArticleSourceID, Types.ArticleSource>(articleSourceDBStable.vals(), Nat.equal, Hash.hash);

    system func preupgrade() {
        articleSourceDBStable := Iter.toArray(articleSourceDB.entries());
    };

    system func postupgrade() {
        articleSourceDBStable := [];
    };


    // ////////////
    // FUNCTIONS
    // ////////////


    public shared(msg) func addArticleSource(body : ?Text) : async Result.Result<Text, Text> {
        assert (msg.caller == Principal.fromText("xyfu2-4yaaa-aaaak-aeaaa-cai"));
        let entry : Types.ArticleSource = {
            id = articleSourceID;
            timestamp = Time.now();
            body = body;
        };
        articleSourceDB.put(articleSourceID, entry);
        articleSourceID += 1;
        return #ok("added source to article");
    };


    // Update ArticleSource with ID
    public shared(msg) func updateArticleSource(sourceID : ?Nat, body : ?Text) : async Result.Result<Text, Text> {
        assert (msg.caller == Principal.fromText("xyfu2-4yaaa-aaaak-aeaaa-cai"));
        switch (sourceID) {
            case (null) {#err("this source does not exist")};
            case (?found) {
                let entry = articleSourceDB.get(found);
                switch (entry) {
                    case (null) {#err("this source does not exist")};
                    case (?found) {
                        let data : Types.ArticleSource = {
                            id = found.id;
                            timestamp = found.timestamp;
                            body = body;
                        };
                        articleSourceDB.put(found.id, data);
                        #ok("source successfully updated");
                    };
                };
            };
        };
    };


    // Remove ArticleSource with ID
    public shared(msg) func removeArticleSource(sourceID : ?Nat) : async Result.Result<Text, Text> {
        assert (msg.caller == Principal.fromText("xyfu2-4yaaa-aaaak-aeaaa-cai"));
        switch (sourceID) {
            case (null) {#err("this source does not exist")};
            case (?found) {
                let entry = articleSourceDB.get(found);
                switch (entry) {
                    case (null) {#err("this source does not exist")};
                    case (?found) {
                        articleSourceDB.delete(found.id);
                        #ok("source successfully removed");
                    };
                };
            };
        };
    };


    // Get all sources for an article
    public query func getAllArticleSources() : async [(Types.ArticleSourceID, Types.ArticleSource)] {
        let result : [(Types.ArticleSourceID, Types.ArticleSource)] = Iter.toArray<(Types.ArticleSourceID, Types.ArticleSource)>(articleSourceDB.entries());
        return result;
    };


    // Get a specific source for an article
    public query func getArticleSource(id : Types.ArticleSourceID) : async ?Types.ArticleSource {
        let entry : ?Types.ArticleSource = switch (articleSourceDB.get(id)) {
            case (null) {null};
            case (?found) {?found};
        };
        return entry;
    };


    // This is to fill up this canister with content to vote on
    public shared(msg) func addSource(body: ?Text) : async Result.Result<Text, Text> {
        assert (msg.caller == owner);
        let data : Types.ArticleSource = {
            id = articleSourceID;
            timestamp = Time.now();
            body = body;
        };
        articleSourceDB.put(articleSourceID, data);
        articleSourceID += 1;
        return #ok("added dummy data to webpage");
    };



    // ////////////
    // HTTP ROUTES
    // ////////////


    // Simple dynamic routes to catch URLs of format /article/<ARTICLE_ID>
    // Can trap and matches any digit at the end of a string. Also somewhat messy...
    public query func http_request(request : Types.HttpRequest) : async Types.HttpResponse {
        if (request.method == "GET") {
            let pattern : Text.Pattern = #char('/');
            let dynamicURL = Array.reverse(Iter.toArray(Text.split(request.url, pattern)));
            let param = textToNat(dynamicURL[0]);
            if (param == null) {
                return {
                    status_code = 404;
                    headers = [("content-type", "text-plain")];
                    body = "404 invalid URL";
                };
            } else {
                let blob : ?Blob = getContentForURL(param);
                switch (blob) {
                    case (null) {
                        return {
                            status_code = 404;
                            headers = [("content-type", "text-plain")];
                            body = "404 invalid URL";
                        };
                    };
                    case (?found) {
                        return {
                            status_code = 200;
                            headers = [("content-type", "text-plain")];
                            body = found;
                        };
                    };
                };
            };
        } else { // no GET request
            return {
                status_code = 404;
                headers = [("content-type", "text-plain")];
                body = "404 invalid URL";
            };
        };
    };



    // ///////////////
    // HELPER
    // /////////////

    
    // Helper function: Convert Text to Nat
    // Credit: https://forum.dfinity.org/t/motoko-convert-text-123-to-nat-or-int-123/7033
    private func textToNat( txt : Text) : ?Nat {
        if (txt.size() <= 0) {
            return null;
        } else {
            let chars = txt.chars();
            var num : Nat = 0;
            for (v in chars) {
                let char = switch (Char.isDigit(v)) {
                    case (false) {return null};
                    case (true) {
                        let charToNum = Nat32.toNat(Char.toNat32(v)-48);
                        num := num * 10 + charToNum;
                    };
                };
            };
            return ?num;
        };
    };


    // Helper function: Take an optional paramter of Nat and switch your way through it
    private func getContentForURL(param : ?Nat) : ?Blob {
        switch (param) {
            case (null) {return null};
            case (?validParam) {
                let entry = articleSourceDB.get(validParam);
                switch (entry) {
                    case (null) {return null};
                    case (?found) {
                        switch (found.body) {
                            case (null) {return null};
                            case (?validText) {
                                return ?Text.encodeUtf8(validText);
                            };
                        };
                    };
                };
            };
        };
    };

}