import "@stdlib/deploy";
import "@stdlib/ownable";

// Structure to represent a candidate
struct Candidate {
    address: Address;  // Added address to track who is the candidate
    name: String;
    voteCount: Int as uint32;
}

// Structure to track voters
struct Voter {
    hasVoted: Bool;
    votedFor: Int as uint32;
}

// Message to register
message Register {
    name: String;
}

// Message to start election
message StartElection {
    duration: Int as uint32;
}

// Message to start registration
message StartRegistration {
    duration: Int as uint32;
}

// Message to vote
message Vote {
    candidate: Int as uint32;
}

contract ElectionContract with Deployable, OwnableTransferable {
    owner: Address;
    candidateRegistrationFee: Int as coins = ton("0.1");  // Fee to register as candidate
    candidates: map<Int, Candidate>;
    voters: map<Address, Voter>;
    candidateCount: Int as uint32;
    registrationOpen: Bool;  // Period when candidates can register
    votingOpen: Bool;
    registrationEndTime: Int as uint256;
    votingEndTime: Int as uint256;
    
    init() {
        self.owner = sender();
        self.candidateCount = 0;
        self.registrationOpen = false;
        self.votingOpen = false;
        self.registrationEndTime = 0;
        self.votingEndTime = 0;
    }

    // Owner starts candidate registration period
    receive(msg: StartRegistration) {
        require(sender() == self.owner, "Only owner can start registration");
        require(!self.registrationOpen, "Registration is already open");
        require(!self.votingOpen, "Voting has already started");
        
        self.registrationOpen = true;
        self.registrationEndTime = now() + (msg.duration * 3);
    }

    // Anyone can register as a candidate by paying the registration fee
    receive(msg: Register) {
        require(self.registrationOpen, "Registration is not open");
        require(now() < self.registrationEndTime, "Registration period has ended");

        // Check if address is already a candidate
        let senderAddr: Address = sender();
        let id: Int = 0;
        repeat(self.candidateCount) {
            id = id + 1;
            let candidate: Candidate? = self.candidates.get(id);
            require(candidate == null || candidate!!.address != senderAddr, "Already registered as candidate");
        }
        
        self.candidateCount = self.candidateCount + 1;
        self.candidates.set(self.candidateCount, Candidate{
            address: senderAddr,
            name: msg.name,
            voteCount: 0
        });
    }

    // End registration period and start voting
    receive(msg: StartElection) {
        require(sender() == self.owner, "Only owner can start voting");
        require(self.registrationOpen, "Registration never started");
        require(!self.votingOpen, "Voting is already open");
        require(now() >= self.registrationEndTime, "Registration period not yet ended");
        require(self.candidateCount > 1, "Need at least 2 candidates");
        
        self.registrationOpen = false;
        self.votingOpen = true;
        self.votingEndTime = now() + (msg.duration * 3);
    }

    // Cast a vote - any address can vote once
    receive(msg: Vote) {
        require(self.votingOpen, "Voting is not open");
        require(now() < self.votingEndTime, "Voting period has ended");
        
        let voter: Voter? = self.voters.get(sender());
        require(voter == null || !voter!!.hasVoted, "Already voted");
        
        let candidate: Candidate? = self.candidates.get(msg.candidate);
        require(candidate != null, "Invalid candidate");
        
        // Update candidate vote count
        self.candidates.set(msg.candidate, Candidate{
            address: candidate!!.address,
            name: candidate!!.name,
            voteCount: candidate!!.voteCount + 1
        });
        
        // Mark voter as having voted
        self.voters.set(sender(), Voter{
            hasVoted: true,
            votedFor: msg.candidate
        });
    }

    // End voting
    receive("endVoting") {
        require(sender() == self.owner, "Only owner can end voting");
        require(self.votingOpen, "Voting is not open");
        require(now() >= self.votingEndTime, "Voting period not yet ended");
        
        self.votingOpen = false;
    }

    // Get all candidates
    get fun getAllCandidates(): map<Int, Candidate> {
        let result: map<Int, Candidate> = emptyMap();
        
        let candidateId: Int = 0;
        repeat(self.candidateCount) {
            candidateId = candidateId + 1;
            let candidate: Candidate? = self.candidates.get(candidateId);
            if (candidate != null) {
                result.set(candidateId, candidate!!);
            }
        }
        
        return result;
    }

    // Get winner
    get fun getWinner(): Candidate? {
        require(!self.votingOpen, "Voting is still open");
        
        let winningVoteCount: Int = 0;
        let winningCandidateId: Int = 0;
        
        let candidateId: Int = 0;
        repeat(self.candidateCount) {
            candidateId = candidateId + 1;
            let candidate: Candidate? = self.candidates.get(candidateId);
            
            if (candidate != null && candidate!!.voteCount > winningVoteCount) {
                winningVoteCount = candidate!!.voteCount;
                winningCandidateId = candidateId;
            }
        }
        
        return self.candidates.get(winningCandidateId);
    }

    // Get registration status
    get fun getRegistrationStatus(): Bool {
        return self.registrationOpen;
    }

    // Get remaining registration time
    get fun getRemainingRegistrationTime(): Int {
        if (!self.registrationOpen) {
            return 0;
        }
        let remainingTime: Int = self.registrationEndTime - now();
        return remainingTime > 0 ? remainingTime : 0;
    }

    // Get voting status
    get fun getVotingStatus(): Bool {
        return self.votingOpen;
    }

    // Get remaining voting time
    get fun getRemainingVotingTime(): Int {
        if (!self.votingOpen) {
            return 0;
        }
        let remainingTime: Int = self.votingEndTime - now();
        return remainingTime > 0 ? remainingTime : 0;
    }

    // Get registration fee
    get fun getRegistrationFee(): Int {
        return self.candidateRegistrationFee;
    }
}
