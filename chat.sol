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
    mapping(address => bool) isSpeaker;
    
    struct Message {
        address sender;
        bytes32 text;
    }
    Message[5] public messages; // a ring buffer of recent messages (clients need to store history)
    uint public nextMessageIdx = 0;
    
    mapping(address => bytes32) public nicknames;
	bytes32 lastNick;
    
    function Chat(uint initActivationPrice, uint initSpeechPrice) {
        king = msg.sender;
        activationPrice.global = initActivationPrice;
        speechPrice.global = initSpeechPrice;
    }

    function kill() {
        selfdestruct(king);
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
    
    // a person must be activated to:
    // * be assigned a name
    // * speak
    // * become an executive officer for the week
    function activate() costs(activationPrice.global, activationPrice.personal) {
        isSpeaker[msg.sender] = true;
    }
    
    function speak(bytes32 text) costs(speechPrice.global, speechPrice.personal) activated {
        messages[nextMessageIdx].text = text;
        messages[nextMessageIdx].sender = msg.sender;
        nextMessageIdx = (nextMessageIdx + 1) % messages.length;
    }
    
    // ********* Modify locked-down parameters **********
    
    modifier isKing() {
        if (msg.sender != king) {
            throw;
        }
        _
    }
    
    function setNickname(address speaker, bytes32 nick) isKing {
        if (!isSpeaker[speaker]) {
            throw;
        }
        
        nicknames[speaker] = nick;
		lastNick = nick;
    }
    
    function deleteNickname(address speaker) isKing {
        delete nicknames[speaker];
    }
    
    function setDefaultActivationPrice(uint price) isKing {
        activationPrice.global = price;
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
    
    function deletePersonalSpeechPrice(address speaker) isKing {
        delete speechPrice.personal[speaker];
    }
    
    // fallbacks
    function collect() {
        king.send(this.balance);
    }
}

