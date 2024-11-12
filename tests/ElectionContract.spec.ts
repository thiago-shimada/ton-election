import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { ElectionContract } from '../wrappers/ElectionContract';
import '@ton/test-utils';

describe('ElectionContract', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let electionContract: SandboxContract<ElectionContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        electionContract = blockchain.openContract(await ElectionContract.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await electionContract.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: electionContract.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and electionContract are ready to use
    });

    it('should increase', async () => {
        const [wallet1, wallet2, wallet3] = await blockchain.createWallets(3);

        await electionContract.send(
            deployer.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "StartRegistration",
            duration: 1n
        }
        )

        await electionContract.send(
            wallet1.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Register",
            name: "Thiago"
        }
        )

        await electionContract.send(
            wallet2.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Register",
            name: "João"
        }
        )

        await sleep(3500);

        await electionContract.send(
            deployer.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "StartElection",
            duration: 1n
        }
        )

        await electionContract.send(
            wallet1.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Vote",
            candidate: 1n
        }
        )

        await electionContract.send(
            wallet1.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Vote",
            candidate: 1n
        }
        )

        await electionContract.send(
            wallet2.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Vote",
            candidate: 2n
        }
        )

        await electionContract.send(
            wallet3.getSender(),
            {
                value: toNano("0.02")
            }, {
            $$type: "Vote",
            candidate: 1n
        }
        )

        await sleep(3500);

        await electionContract.send(
            deployer.getSender(),
            {
                value: toNano("0.02")
            },
            "endVoting"
        )

        const candidates = await electionContract.getGetAllCandidates();
        candidates.values().forEach((value, idx) => {
            console.log(`Candidato ${idx + 1}: ${value.name}; Votos: ${value.voteCount}`)
        })

        const winner = await electionContract.getGetWinner();
        console.log(winner)
    }, 20000)
});

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))
