import Web3 from 'web3';
import solc from 'solc';
import fs from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';
import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';

export const LOCAL_PROVIDER_URL = 'http://localhost:7001'
export const REMOTE_HTTP_PROVIDER_URL = process.env.REMOTE_RPC_URL;
if (!REMOTE_HTTP_PROVIDER_URL){
    throw new Error("REMOTE_RPC_URL environment variable not set");
}
const DEFAULT_GAS_PRICE = '1';
const DEFAULT_GAS_LIMIT = '10000000';
const DEFAULT_CHAIN_ID = 50505050;
const SOLC_VERSION = '0.8.24';

const MPC_INTERFACE_PATH = "lib/onchain/contracts/MpcInterface.sol";
const MPC_CORE_PATH = "lib/onchain/contracts/MpcCore.sol";
const CONTRACTS_ADDRESS_PATH = "contracts/";
const PROTO_FILE_PATH = "proto/userInteractor.proto";

const RECEIPT_POLL_INTERVAL = 1000;

export class SodaWeb3Helper {
    constructor(privateKey, httpProviderUrl, chainId = DEFAULT_CHAIN_ID) {
        this.privateKey = privateKey;

        this.web3 = new Web3(httpProviderUrl);
        if (!this.web3.eth.net.isListening()) {
            console.log("Failed to connect to the node.");
            return;
        }
        console.log(`Connected to the node at ${httpProviderUrl}`);

        this.web3.eth.accounts.wallet.add(privateKey);
        this.account = this.web3.eth.accounts.wallet[0];
        console.log(`Account address is ${this.account.address}`);

        this.chainId = chainId;
        console.log(`Chain ID: ${this.chainId}`);

        this.contracts = {};
        console.log('SodaWeb3Helper initialized');
    }

    async setupContract(contractPath, contractName, contractId, overwrite = false, MpcInterfacePath = MPC_INTERFACE_PATH, mpcCorePath = MPC_CORE_PATH, address_path=CONTRACTS_ADDRESS_PATH) {
        if (contractId in this.contracts && !overwrite) {
            console.log(`Contract with id ${contractId} already exists. Use the 'overwrite' parameter to overwrite it.`);
            return false;
        }
    
        try {
            const compiledContract = await this.compileContract(contractPath, contractName, MpcInterfacePath, mpcCorePath, address_path);
            const bytecode = compiledContract.evm.bytecode.object;
            const contractAbi = JSON.parse(compiledContract.metadata).output.abi;
            this.contracts[contractId] = new this.web3.eth.Contract(contractAbi, null, { data: bytecode });
            return true;
        } catch (error) {
            console.error(`Failed to compile the contract: ${error}`);
            return false;
        }
    }

    getContract(contractId) {
        if (!(contractId in this.contracts)) {
            console.log(`Contract with id ${contractId} does not exist. Use the 'setup_contract' method to set it up.`);
            return null;
        }
        return this.contracts[contractId];
    }

    getAccount(){
        return this.account;
    }
    

    generateRandomAccount(){
        return this.web3.eth.accounts.create();
    }

    async resolveSolcCompiler(installedVersion, solc, SOLC_VERSION){
        let compiler;
        // If installed version is 0.8.x (compatible with SOLC_VERSION), use it directly
        // Solidity 0.8.x versions are generally backward compatible
        if (installedVersion.includes('0.8.')) {
            console.log(`Using installed solc version (${installedVersion}) as it's compatible with ${SOLC_VERSION}`);
            compiler = solc;
        } else {
            // Otherwise, try to load the specific remote version
            console.log(`Attempting to load remote solc version ${SOLC_VERSION}...`);
            try {
                compiler = await new Promise((resolve, reject) => {
                    // Try without 'v' prefix first
                    solc.loadRemoteVersion(SOLC_VERSION, (err, solcVersion) => {
                        if (err) {
                            // Try with 'v' prefix
                            solc.loadRemoteVersion(`v${SOLC_VERSION}`, (err2, solcVersion2) => {
                                if (err2) {
                                    reject(new Error(`Failed to load remote version. Tried '${SOLC_VERSION}' and 'v${SOLC_VERSION}'. Errors: ${err.message}, ${err2.message}. You may need to install solc manually or use a compatible version.`));
                                } else {
                                    console.log(`Loaded solc compiler successfully (with v prefix)`);
                                    resolve(solcVersion2);
                                }
                            });
                        } else {
                            console.log(`Loaded solc compiler successfully`);
                            resolve(solcVersion);
                        }
                    });
                });
            } catch (err) {
                throw new Error(`Failed to load solc version ${SOLC_VERSION}: ${err.message}. Installed version is ${installedVersion}.`);
            }
        }
        return compiler;
    }

    async compileContract(filePath, fileName, MpcInterfacePath = MPC_INTERFACE_PATH, mpcCorePath = MPC_CORE_PATH, address_path=CONTRACTS_ADDRESS_PATH) {
        const solidityCode = this.readSolidityCode(filePath + fileName);

        console.log(`Compiling ${filePath + fileName}...`);
        console.log(`Loading solc compiler version ${SOLC_VERSION}...`);

        // Check installed version first
        const installedVersion = solc.version();
        console.log(`Installed solc version: ${installedVersion}`);
        
        const compiler = await this.resolveSolcCompiler(installedVersion, solc, SOLC_VERSION);

        // Find node_modules path 
        const bubbleDir = path.resolve(process.cwd());
        const nodeModulesPath = path.join(bubbleDir, 'node_modules');
        
        if (!fs.existsSync(nodeModulesPath)) {
            throw new Error(`node_modules directory not found at ${nodeModulesPath}. Run 'npm install' first.`);
        }
        
        const sources = {
            [fileName]: { content: solidityCode },
        }
        if (MpcInterfacePath != "") {
            sources["MpcInterface.sol"] = { content: this.readSolidityCode(MpcInterfacePath) };
        }
        if (mpcCorePath != "") {
            sources["MpcCore.sol"] = { content: this.readSolidityCode(mpcCorePath) };
        }
        if (address_path != "") {
            sources["GCHandlerAddress.sol"] = { content: this.readSolidityCode(address_path + "GCHandlerAddress.sol") };
            sources["GCACLAddress.sol"] = { content: this.readSolidityCode(address_path + "GCACLAddress.sol") };
        }
    
        const input = {
            language: 'Solidity',  
            sources: sources,
            settings: {
                viaIR: true,  
                optimizer: {   
                    enabled: true,
                    runs: 200
                },
                outputSelection: {
                    '*': {
                        '*': ['abi', 'metadata', 'evm.bytecode', 'evm.bytecode.sourceMap']
                    }
                },
                remappings: [
                    `@openzeppelin/=${nodeModulesPath}/@openzeppelin/`
                ]
            }
        };

        const compiledSol = JSON.parse(compiler.compile(JSON.stringify(input), { import: this.findImports(nodeModulesPath) }));
    
        // Check for compilation errors
        if (compiledSol.errors) {
            const errors = compiledSol.errors.filter(e => e.severity === 'error');
            if (errors.length > 0) {
                const errorMessages = errors.map(e => `${e.sourceLocation?.file || 'unknown'}:${e.sourceLocation?.line || '?'} ${e.message}`).join('\n');
                throw new Error(`Compilation failed for contract ${fileName.split('.')[0]}:\n${errorMessages}`);
            }
        }
    
        if (!compiledSol.contracts || !compiledSol.contracts[fileName] || !compiledSol.contracts[fileName][fileName.split('.')[0]]) {
            const errorMsg = compiledSol.errors ? 
                compiledSol.errors.map(e => e.message).join('\n') : 
                'Unknown compilation error';
            throw new Error(`Compilation failed for contract ${fileName.split('.')[0]}: ${errorMsg}`);
        }

        return compiledSol.contracts[fileName][fileName.split('.')[0]];
    }

    findImports(nodeModulesPath) {
        return (importPath) => {
            // The import callback receives the original import path from the contract
            // We need to resolve it based on our remapping: @openzeppelin/ -> node_modules/@openzeppelin/
            
            // Handle @openzeppelin imports
            if (importPath.startsWith('@openzeppelin/')) {
                // Apply the remapping: @openzeppelin/contracts/access/Ownable.sol 
                // -> node_modules/@openzeppelin/contracts/access/Ownable.sol
                // Remove the @openzeppelin/ prefix and join with node_modules
                const pathAfterPrefix = importPath.replace(/^@openzeppelin\//, '');
                const remappedPath = path.join(nodeModulesPath, '@openzeppelin', pathAfterPrefix);
                
                // Try the remapped path
                if (fs.existsSync(remappedPath)) {
                    const stat = fs.statSync(remappedPath);
                    if (stat.isFile()) {
                        return { contents: fs.readFileSync(remappedPath, 'utf8') };
                    }
                }
                
                // Try with .sol extension if the path doesn't have it
                if (!remappedPath.endsWith('.sol')) {
                    const pathWithSol = remappedPath + '.sol';
                    if (fs.existsSync(pathWithSol)) {
                        return { contents: fs.readFileSync(pathWithSol, 'utf8') };
                    }
                }
            }
            
            // For other imports, try to resolve them
            // First try as absolute path
            if (path.isAbsolute(importPath) && fs.existsSync(importPath)) {
                return { contents: fs.readFileSync(importPath, 'utf8') };
            }
            
            // Try relative to current working directory
            const relativePath = path.resolve(importPath);
            if (fs.existsSync(relativePath)) {
                return { contents: fs.readFileSync(relativePath, 'utf8') };
            }
            
            // Return error if not found
            return { error: `File not found: ${importPath}` };
        };
    }

    async deployContract(contractId, constructorArgs = [], gasLimit = DEFAULT_GAS_LIMIT, gasPrice = DEFAULT_GAS_PRICE) {
        const contract = this.contracts[contractId];
        const funcToCall = contract.deploy({
            data: contract.options.data,
            arguments: constructorArgs
        });
        const nonce = await this.web3.eth.getTransactionCount(this.account.address);
        const constructTxn = {
            from: this.account.address,
            data: funcToCall.encodeABI(),
            chainId: this.chainId,
            nonce: nonce,
            gas: gasLimit,
            gasPrice: this.web3.utils.toWei(gasPrice.toString(), 'gwei')
        };
        const receipt = await this.signAndSendTransaction(constructTxn);
        
        if (receipt) {
            console.log(`Contract deployed at: ${receipt.contractAddress}`);
            this.contracts[contractId].options.address = receipt.contractAddress;
        }
    
        return receipt;
    }

    // Function to get the current nonce for a given account
    async getCurrentNonce(account=this.account.address) {  
        try {
            return await this.web3.eth.getTransactionCount(account);
        } catch (error) {
            console.error('Error fetching nonce:', error);
            throw error;
        }
    }

    async callContractView(contractId, funcName, funcArgs = []) {
        if (!(contractId in this.contracts)) {
            console.log(`Contract with id ${contractId} does not exist. Use the 'setupContract' method to set it up.`);
            return null;
        }
    
        const contract = this.contracts[contractId];
        const func = contract.methods[funcName];

        try {
            const result = await func(...funcArgs).call({ from: this.account.address });
            return result;
        } catch (error) {
            console.error(`Failed to call function ${funcName}: ${error}`);
            return null;
        }
    }

    async estimateGas(contractId, funcName, funcArgs = []) {
        if (!(contractId in this.contracts)) {
            console.log(`Contract with id ${contractId} does not exist. Use the 'setupContract' method to set it up.`);
            return null;
        }
    
        const contract = this.contracts[contractId];
        const funcToCall = contract.methods[funcName](...funcArgs);
        return funcToCall.estimateGas({ from: this.account.address });
    }

    async callContractTransaction(contractId, funcName, funcArgs = [], gasLimit = DEFAULT_GAS_LIMIT, gasPrice = DEFAULT_GAS_PRICE) {
        if (!(contractId in this.contracts)) {
            console.log(`Contract with id ${contractId} does not exist. Use the 'setupContract' method to set it up.`);
            return null;
        }
    
        const contract = this.contracts[contractId];
        const funcToCall = contract.methods[funcName](...funcArgs);
        const receipt = await this.callContractFunctionTransaction(funcToCall, gasLimit, gasPrice);
        return receipt;
    }

    async callContractFunctionTransaction(func, gasLimit = DEFAULT_GAS_LIMIT, gasPrice = DEFAULT_GAS_PRICE) {
        const nonce = await this.web3.eth.getTransactionCount(this.account.address);
        const transaction = {
            from: this.account.address,
            chainId: this.chainId,
            nonce: nonce,
            gas: gasLimit,
            gasPrice: this.web3.utils.toWei(gasPrice.toString(), 'gwei')
        };
        const receipt = await this.sendTransaction(func, transaction);
        return receipt;
    }

    /**
     * This asynchronous function calls a contract function as a transaction without wait for it to be mined.
     *
     * @param {Function} func - The contract function to call.
     * @param {Object} contract - The contract instance.
     * @param {Number} gasLimit - The maximum gas that can be used for transaction, defaults to DEFAULT_GAS_LIMIT.
     * @param {Number} gasPrice - The price of gas in wei for this transaction, defaults to DEFAULT_GAS_PRICE.
     *
     * @returns {Promise} - A promise that resolves to the result of the sendTransaction function.
     */
    async callContractFunctionTransactionAsync(func, nonce, gasLimit = DEFAULT_GAS_LIMIT, gasPrice = DEFAULT_GAS_PRICE) {
        const transaction = {
            from: this.account.address,
            chainId: this.chainId,
            nonce: nonce,   
            gas: gasLimit,
            gasPrice: this.web3.utils.toWei(gasPrice.toString(), 'gwei')
        };

        return this.sendTransaction(func, transaction, true);
    }

    async sendTransaction(funcToCall, transaction, isAsync = false) {
        try {
            if (isAsync) {
                // If async, return the transaction hash immediately after sending
                return new Promise((resolve, reject) => {
                    funcToCall.send(transaction)
                        .on('transactionHash', hash => {
                            resolve(hash);  // Resolve the promise with the hash
                        })
                        .on('error', error => {
                            console.error('Error send transaction:', error);
                            reject(error);  // Reject the promise on error
                        });
                });
            } else {
                // If not async, wait for the receipt
                const tx = await funcToCall.send(transaction);
                const receipt = await this.web3.eth.getTransactionReceipt(tx.transactionHash);
                return receipt;
            }
    
        } catch (error) {
            console.error('Error send transaction:', error);
            throw error;
        }
    }   

    async signAndSendTransaction(transaction) {
        try {
            const signedTx = await this.web3.eth.accounts.signTransaction(transaction, this.account.privateKey);
            const tx = await this.web3.eth.sendSignedTransaction(signedTx.rawTransaction);
            const receipt = await this.web3.eth.getTransactionReceipt(tx.transactionHash);
            return receipt;
    
        } catch (error) {
            console.error('Error sign and send transaction:', error);
            throw error;
        }
    }  

    async waitForTransactionReceipt(txHash) {
        
        let txReceipt = null;
        // Keep trying until we get the receipt
        while (txReceipt === null) {
            try {
                txReceipt = await this.web3.eth.getTransactionReceipt(txHash);
                if (txReceipt !== null) {
                    return txReceipt;
                }
            } catch (error) {
                if (error.message.includes('not found')) {
                    continue;
                } else {
                    console.error('Unexpected error:', error);
                    break;
                }
            }
            // Wait for 1 second before trying again
            await new Promise(resolve => setTimeout(resolve, RECEIPT_POLL_INTERVAL));
        }
    }

    readSolidityCode(filePath) {
        if (!fs.existsSync(filePath)) {
            throw new Error(`The file ${filePath} does not exist`);
        }
        return fs.readFileSync(filePath, 'utf8');
    }
    
}

export function createUserInteractorClient(user_interactor_url){
    // Load the proto file dynamically
    const currentDir = process.cwd();
    const protoPath = path.join(currentDir, PROTO_FILE_PATH);
    
    const packageDefinition = protoLoader.loadSync(protoPath, {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true
    });
    
    const protoDescriptor = grpc.loadPackageDefinition(packageDefinition);
    const userInteractorProto = protoDescriptor.bubbleProto;
    
    // Create a gRPC client
    const client = new userInteractorProto.UserInteractorService(
        user_interactor_url,
        grpc.credentials.createInsecure()
    );

    return client;
}

