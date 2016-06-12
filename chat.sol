contract AutonomousCollective {
	address public executiveOfficer; //for the week
	enum Proposed { NewActivationPrice, NewSpeechPrice, NewNickname }
	struct Proposal {
		address proposer;
		Proposed action;
		address target; // empty target has meaning, like an empty target on a new speech price means a new global speech price
		bool executed;
		bytes32 payload; //this will be the new nickname for the NewNickname proposal, for example
	}
	Proposal[] proposals;
	uint nextProposalIdx;
	uint maxProposals;
	Chat chat;

	function AutonomousCollective(uint _maxProposals) {
		executiveOfficer = msg.sender;
		maxProposals = _maxProposals;
		proposals.length = _maxProposals;
		chat = new Chat(1000 wei, 100 wei, 10);
	}

	modifier isExecutiveOfficer {
		if (msg.sender != executiveOfficer) {
			throw; // only the executive officer for the week can make proposals
		}
		_
	}

	function makeProposal(Proposed action, address target, bytes32 payload) isExecutiveOfficer {
		proposals[nextProposalIdx] = Proposal(msg.sender, action, target, false, payload);
		nextProposalIdx = (nextProposalIdx + 1) % maxProposals;
	}

	function executeProposal(uint index) {
		Proposal proposal = proposals[index];
		if (proposal.executed) {
			throw; // don't execute the same proposal twice
		}
		if (proposal.action == Proposed.NewNickname) {
			chat.setNickname(proposal.target, proposal.payload);
		}
		else {
			throw; //TODO proposal not implemented
		}
	}
}

contract Chat {
    
    // The king address has full rights to change prices, nicknames, etc.
    // The intention is that the address is a contract with rules governing changes
    // This address also collects all revenue immediately.
    address public king;
    
    struct PriceList {
        uint global;
        mapping(address => uint) personal;
    }
    PriceList activationPrice;
    PriceList speechPrice;
    mapping(address => bool) public isSpeaker;
    
    struct Message {
        address sender;
        uint timestamp;
        bytes32 text;
    }
    Message[] public messages; // a ring buffer of recent messages (clients need to store history)
    uint public nextMessageIdx = 0;
    uint8 public messageBufferSize;
    
    mapping(address => bytes32) public nicknames;
    
    function Chat(uint initActivationPrice, uint initSpeechPrice, uint8 _messageBufferSize) {
        king = msg.sender;
        activationPrice.global = initActivationPrice;
        speechPrice.global = initSpeechPrice;
        messages.length = _messageBufferSize;
        messageBufferSize = _messageBufferSize;
    }

    // tried to pass in PriceList here, but solidity wouldn't let me access a
    // struct member inside a modifier...
    modifier costs(uint global, mapping(address=>uint) personal) {
        uint price = personal[msg.sender];
        if (price == 0) {
            price = global;
        }
        
        if (msg.value < price) {
            throw;
        }
        else if (msg.value > price) {
            msg.sender.send(msg.value - price); //return over-payment
        }
        
        king.send(msg.value);
        _
    }
    
    modifier activated() {
        if (!isSpeaker[msg.sender]) {
            throw;
        }
        _
    }
    
    /*
    Bailing on this function, it's giving me an error: "Type is required to live outside storage"
    This may be a bug, according to: http://ethereum.stackexchange.com/questions/983/how-to-pass-struct-mappings-to-solidity-functions
    Manually repeating for new (holds nose)
    function getPersonalPrice(uint global, mapping(address=>uint) personal, address forMember) internal returns (uint price) {
        price = personal[forMember];
        if (price == 0) {
            price = global;
        }
    }
    */

    // a person must be activated to:
    // * be assigned a name
    // * speak
    // * become an executive officer for the week
    function activate() costs(activationPrice.global, activationPrice.personal) {
        if (isSpeaker[msg.sender]) {
            throw; // reverse the charge if sender is already activated
        }
        isSpeaker[msg.sender] = true;
    }
    
    function speak(bytes32 text) costs(speechPrice.global, speechPrice.personal) activated {
        messages[nextMessageIdx].text = text;
        messages[nextMessageIdx].sender = msg.sender;
        messages[nextMessageIdx].timestamp = now;
        nextMessageIdx = (nextMessageIdx + 1) % messages.length;
    }
    
    // ********* Modify locked-down parameters **********
    
    modifier isKing() {
        if (msg.sender != king) {
            throw;
        }
        _
    }

    function kill() isKing {
        selfdestruct(king);
    }
    
    function setNickname(address speaker, bytes32 nick) isKing {
        if (!isSpeaker[speaker]) {
            throw;
        }
        
        nicknames[speaker] = nick;
    }
    
    function deleteNickname(address speaker) isKing {
        delete nicknames[speaker];
    }
    
    function setDefaultActivationPrice(uint price) isKing {
        activationPrice.global = price;
    }
    
    function getActivationPrice(address forAccount) constant returns (uint price) {
        price = activationPrice.personal[forAccount];
        if (price == 0) {
            price = activationPrice.global;
        }
        //return getPersonalPrice(activationPrice.global, activationPrice.personal, forAccount);
    }

    function setDefaultSpeechPrice(uint price) isKing {
        speechPrice.global = price;
    }
    
    function setPersonalSpeechPrice(address speaker, uint price) isKing {
        if (!isSpeaker[speaker]) {
            throw;
        }
        
        speechPrice.personal[speaker] = price;
    }
    
    function getSpeechPrice(address forAccount) constant returns (uint price) {
        price = speechPrice.personal[forAccount];
        if (price == 0) {
            price = speechPrice.global;
        }
    }

    function deletePersonalSpeechPrice(address speaker) isKing {
        delete speechPrice.personal[speaker];
    }
    
    // fallbacks
    function collect() {
        king.send(this.balance);
    }
}

