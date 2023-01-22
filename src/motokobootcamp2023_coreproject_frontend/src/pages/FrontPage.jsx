import 'bootstrap/dist/css/bootstrap.min.css';
import * as React from 'react';
import { useState, useEffect } from 'react';
import { Button } from 'react-bootstrap';

import { idlFactory } from "../../../declarations/motokobootcamp2023_coreproject_dao/motokobootcamp2023_coreproject_dao.did.js";
import { motokobootcamp2023_coreproject_dao } from "../../../declarations/motokobootcamp2023_coreproject_dao";


const FrontPage = ({whitelist}) => {

    const [proposals, setProposals] = useState([]);


    useEffect(() => {
        getProposals();
    }, []);


    // Get all active proposals
    const getProposals = async () => {
        const resultArray = [];
        const response = await motokobootcamp2023_coreproject_dao.get_all_proposals();
        for (var entry of response) {
            const data = {
                id: entry[1].id,
                headline: entry[1].headline,
                body: entry[1].body,
                desiredChange: entry[1].desiredChange,
                status: entry[1].status,
                action: entry[1].action,
                votesCon: entry[1].votesCon,
                votesPro: entry[1].votesPro
            };
            console.log(data);
            resultArray.push(data);
        };
        setProposals(resultArray.reverse());
    };


    // Vote
    const vote = async (proposalID, proCon) => {
        const myActor = await window.ic.plug.createActor({
            canisterId: whitelist[0],
            interfaceFactory: idlFactory
        });
        if (proCon == "pro") {
            const response = await myActor.vote(proposalID, {pro: null});
            console.log(response);
        } else {
            const response = await myActor.vote(proposalID, {con: null});
            console.log(response);
        };
    };
    


    return (
        <>
            <div className="container-fluid above-the-fold">
                <div className="row p-lg-5 p-md-2">
                    <div className="col">
                        <h1><strong>Proposals</strong></h1>
                        <p>This is a small example of a News DAO where you can work on sources for hypothetical articles. You can choose three actions for your proposal: <strong>add a source</strong>, <strong>remove a source</strong> or <strong>update a source</strong> for an article.</p>
                    </div>
                </div>
                {proposals.map((entry) => (
                    <div className="row p-lg-5 p-md-2">
                        <div className="col p-2 border rounded">
                            <div className="row p-2">
                                <div className="col">
                                    <h1>{entry.headline}</h1>
                                </div>
                            </div>
                            <div className="row p-2">
                                <div className="col">
                                    <strong>Action: </strong>{Object.keys(entry.action)[0]}<br></br>
                                    <strong>Status: </strong>{Object.keys(entry.status)[0]}<br></br>
                                    <strong>Votes Pro: </strong>{Number(entry.votesPro)}/100<br></br>
                                    <strong>Votes Con: </strong>{Number(entry.votesCon)}/100<br></br>
                                </div>
                            </div>
                            <div className="row p-2">
                                <div className="col">
                                    <h5><strong>Desired Change: </strong>{entry.desiredChange}</h5>
                                </div>
                            </div>
                            <div className="row p-2">
                                <div className="col">
                                    <h5><strong>Why? </strong>{entry.body}</h5>
                                </div>
                            </div>
                            {(Object.keys(entry.status)[0] == "active") ?
                                <div className="row p-2">
                                    <div className="col">
                                        <Button className="btn btn-light w-100" onClick={() => vote(Number(entry.id), "pro")}>Vote Pro</Button>
                                    </div>
                                    <div className="col">
                                        <Button className="btn btn-dark w-100" onClick={() => vote(Number(entry.id), "con")}>Vote Con</Button>
                                    </div>
                                </div> :
                                <div className="row p-2">
                                    <div className="col">
                                        <h2><strong>This proposal has already been {Object.keys(entry.status)[0]}</strong></h2>
                                    </div>
                                </div>
                            }
                        </div>
                    </div>
                ))}
            </div>
        </>
    )
  };

export default FrontPage;