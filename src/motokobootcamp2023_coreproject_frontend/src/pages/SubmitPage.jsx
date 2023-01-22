import 'bootstrap/dist/css/bootstrap.min.css';
import * as React from 'react';
import { useState } from 'react';
import { Button } from 'react-bootstrap';

import { idlFactory } from "../../../declarations/motokobootcamp2023_coreproject_dao/motokobootcamp2023_coreproject_dao.did.js";


const SubmitPage = ({whitelist}) => {


    const [headline, setHeadline] = useState();
    const [body, setBody] = useState();
    const [action, setAction] = useState();
    const [sourceID, setSourceID] = useState();
    const [change, setChange] = useState();



    // Submit a proposal
    const submitProposal = async (action, headline, body, sourceID, change) => {
        const myActor = await window.ic.plug.createActor({
            canisterId: whitelist[0],
            interfaceFactory: idlFactory
        });
        if (action == "addSource") {
            const response = await myActor.submit_proposal({addSource: null}, headline, body, [], []);
            console.log(response);
        } else if (action == "updateSource") {
            const response = await myActor.submit_proposal({updateSource: null}, headline, body, [sourceID], [change]);
            console.log(response);
        } else {
            const response = await myActor.submit_proposal({removeSource: null}, headline, body, [sourceID], []);
            console.log(response);
        };
    };


    // <div style="width:100%;height:0;padding-bottom:100%;position:relative;"><iframe src="https://giphy.com/embed/dYXFSE00yCpduJvnUy" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/stickers/transparent-dYXFSE00yCpduJvnUy">via GIPHY</a></p>

    return (
        <>
            <div className="container-fluid above-the-fold">
                <div className="row p-lg-5 p-md-2">
                    <div className="col">
                        <h1><strong>Submit a Proposal</strong></h1>
                        <p>This is a small example of a News DAO where you can work on sources for hypothetical articles. You can choose three actions for your proposal: <strong>add a source</strong>, <strong>remove a source</strong> or <strong>update a source</strong> for an article.</p>
                    </div>
                </div>
                <div className="row p-lg-5 p-md-2">
                    <div className="col">
                        <div className="row">
                            <div className="col my-auto">
                                <div className="container">
                                    <div className="row mx-auto p-2" style={{maxWidth: "600px"}}>
                                        <div className="col">
                                            <form>
                                                <div className="row p-2">
                                                    <div className="col">
                                                        <label>Give Your Proposal a Title</label>
                                                    </div>
                                                    <div className="col">
                                                        <input type="text" onChange={e => setHeadline(e.target.value)} className="w-100"></input>
                                                    </div>
                                                </div>
                                                <div className="row p-2">
                                                    <div className="col">
                                                        <label>Explain Your Proposal</label>
                                                    </div>
                                                    <div className="col">
                                                        <textarea cols="35" rows="4" onChange={e => setBody(e.target.value)} className="w-100"></textarea>
                                                    </div>
                                                </div>
                                                <div className="row p-2">
                                                    <div className="col">
                                                        <select className="form-select" aria-label="Default select example" onChange={e => setAction(e.target.value)}>
                                                            <option defaultValue>Choose an Action</option>
                                                            <option value="addSource">Add a Source</option>
                                                            <option value="updateSource">Update a Source</option>
                                                            <option value="removeSource">Remove a Source</option>
                                                        </select>
                                                    </div>
                                                </div>
                                                {(action == "removeSource") || (action == "updateSource") ?
                                                    <div className="row p-2">
                                                        <div className="col">
                                                            <label>Source ID You Wish to Update</label>
                                                        </div>
                                                        <div className="col">
                                                            <input type="number" onChange={e => setSourceID(Number(e.target.value))}></input>
                                                        </div>
                                                    </div> :
                                                    <></>
                                                }
                                                {(action == "updateSource") ?
                                                    <div className="row p-2">
                                                        <div className="col">
                                                            <label>Provide Your Desired Change</label>
                                                        </div>
                                                        <div className="col">
                                                            <textarea cols="35" rows="4" onChange={e => setChange(e.target.value)}></textarea>
                                                        </div>
                                                    </div> :
                                                    <></>
                                                }
                                            </form>
                                        </div>
                                    </div>
                                    <div className="row mx-auto p-2">
                                        <div className="col">
                                            <Button onClick={() => submitProposal(action, headline, body, sourceID, change)} className="w-100 btn btn-dark btn-lg">Submit Proposal</Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </>
    )
  };

export default SubmitPage;