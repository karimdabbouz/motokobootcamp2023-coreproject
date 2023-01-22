module Types {


    public type UserID = Principal;
    public type ProposalID = Nat;
    public type ArticleSourceID = Nat;
    public type HeaderField = (Text, Text);
    public type NeuronID = Nat;


    public type HttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
    };


    public type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };


    public type ArticleSource = {
        id : Nat;
        timestamp : Int;
        body : ?Text;
    };


    public type Proposal = {
        id : Nat;
        sourceID : ?Nat;
        creator : Principal;
        timestamp : Int;
        action : {#addSource; #updateSource; #removeSource}; // add more governance actions here...
        status : {#active; #passed; #declined};
        headline : Text;
        body : Text;
        desiredChange : ?Text;
        votesPro : Nat;
        votesCon : Nat;
    };


    public type Neuron = {
        id : Nat;
        creator : Principal;
        createdAt : Int;
        dissolveDelay : Int;
        amount : Nat;
        status : {#locked; #dissolving; #dissolved};
    };


}