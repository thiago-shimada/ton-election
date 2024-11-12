import { toNano } from '@ton/core';
import { ElectionContract } from '../wrappers/ElectionContract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const electionContract = provider.open(await ElectionContract.fromInit());

    await electionContract.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(electionContract.address);

    // run methods on `electionContract`
}
