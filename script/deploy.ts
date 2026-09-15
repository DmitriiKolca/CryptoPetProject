import { ethers, NonceManager } from "ethers";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

dotenv.config();

function getArtifact(contractName: string) {
    const artifactPath = path.join(__dirname, `../out/${contractName}.sol/${contractName}.json`);
    if (!fs.existsSync(artifactPath)) {
        throw new Error(`Artifact for ${contractName} not found. Run 'forge build' first.`);
    }
    return JSON.parse(fs.readFileSync(artifactPath, "utf8"));
}

const deployedSelectors = new Set<string>();

function getSelectors(contractName: string, contractInterface: ethers.Interface): string[] {
    const selectors: string[] = [];

    contractInterface.forEachFunction((func) => {
        const selector = func.selector;

        if (deployedSelectors.has(selector)) {
            console.warn(
                `⚠️  [Дубликат пропущен]: Функция "${func.name}" (${selector}) из контракта "${contractName}" уже зарегистрирована в другом фасете!`
            );
            return;
        }

        deployedSelectors.add(selector);
        selectors.push(selector);
    });

    return selectors;
}

async function main() {
    const rpcUrl = process.env.RPC_URL || "http://127.0.0.1:8545";
    const privateKey = process.env.PRIVATE_KEY;

    if (!privateKey) {
        throw new Error("Please provide a PRIVATE_KEY in your .env file");
    }

    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const baseWallet = new ethers.Wallet(privateKey, provider);

    const wallet = new NonceManager(baseWallet);
    console.log(`Deploying contracts with the account: ${baseWallet}`);

    const DiamondCutFacetArtifact = getArtifact("DiamondCutFacet");
    const DiamondArtifact = getArtifact("Diamond");
    const AdminFacetArtifact = getArtifact("AdminFacet");
    const MintFacetArtifact = getArtifact("MintFacet");
    const InitFacetArtifact = getArtifact("InitFacet");

    console.log("Deploying DiamondCutFacet...");
    const DiamondCutFacetFactory = new ethers.ContractFactory(DiamondCutFacetArtifact.abi, DiamondCutFacetArtifact.bytecode, wallet);
    const diamondCutFacet = await DiamondCutFacetFactory.deploy();
    await diamondCutFacet.waitForDeployment();
    const diamondCutFacetAddress = await diamondCutFacet.getAddress();
    console.log(`DiamondCutFacet deployed to: ${diamondCutFacetAddress}`);

    console.log("Deploying Diamond proxy...");
    const DiamondFactory = new ethers.ContractFactory(DiamondArtifact.abi, DiamondArtifact.bytecode, wallet);
    const diamond = await DiamondFactory.deploy(wallet.getAddress(), diamondCutFacetAddress);
    await diamond.waitForDeployment();
    const diamondAddress = await diamond.getAddress();
    console.log(`Diamond Proxy deployed to: ${diamondAddress}`);

    console.log("Deploying operational facets...");
    const AdminFacetFactory = new ethers.ContractFactory(AdminFacetArtifact.abi, AdminFacetArtifact.bytecode, wallet);
    const adminFacet = await AdminFacetFactory.deploy();
    await adminFacet.waitForDeployment();
    const adminFacetAddress = await adminFacet.getAddress();

    const MintFacetFactory = new ethers.ContractFactory(MintFacetArtifact.abi, MintFacetArtifact.bytecode, wallet);
    const mintFacet = await MintFacetFactory.deploy();
    await mintFacet.waitForDeployment();
    const mintFacetAddress = await mintFacet.getAddress();

    const InitFacetFactory = new ethers.ContractFactory(InitFacetArtifact.abi, InitFacetArtifact.bytecode, wallet);
    const initFacet = await InitFacetFactory.deploy();
    await initFacet.waitForDeployment();
    const initFacetAddress = await initFacet.getAddress();

    console.log(`AdminFacet: ${adminFacetAddress}\nMintFacet: ${mintFacetAddress}\nInitFacet: ${initFacetAddress}`);

    const adminInterface = new ethers.Interface(AdminFacetArtifact.abi);
    const mintInterface = new ethers.Interface(MintFacetArtifact.abi);

    const adminSelectors = getSelectors("AdminFacet", adminInterface);
    const mintSelectors = getSelectors("MintFacet", mintInterface);

    const cut = [
        {
            facetAddress: adminFacetAddress,
            action: 0,
            functionSelectors: adminSelectors
        },
        {
            facetAddress: mintFacetAddress,
            action: 0,
            functionSelectors: mintSelectors
        }
    ];

    const initInterface = new ethers.Interface(InitFacetArtifact.abi);
    const initCallData = initInterface.encodeFunctionData("init", [
        "My Crypto Game",
        "MCG",
        "https://mygame.com"
    ]);

    console.log("Executing diamondCut and initializing...");
    const diamondCutContract = new ethers.Contract(diamondAddress, DiamondCutFacetArtifact.abi, wallet);

    const tx = await diamondCutContract.diamondCut(cut, initFacetAddress, initCallData);
    await tx.wait();

    console.log("🎉 Diamond successfully deployed and initialized!");
    console.log(`Final Diamond Address to use in frontend: ${diamondAddress}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
