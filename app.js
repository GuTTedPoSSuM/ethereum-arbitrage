
let web3;
let arbitrageContract;
let userAccount;

const contractAddress = "YOUR_CONTRACT_ADDRESS"; // Replace with deployed contract address
const contractABI = []; // ABI of your contract

async function connectMetaMask() {
    if (window.ethereum) {
        web3 = new Web3(window.ethereum);
        try {
            await ethereum.request({ method: 'eth_requestAccounts' });
            userAccount = (await web3.eth.getAccounts())[0];
            arbitrageContract = new web3.eth.Contract(contractABI, contractAddress);
            console.log("Connected account: ", userAccount);
        } catch (error) {
            console.error("User denied account access", error);
        }
    } else {
        alert("MetaMask is not installed!");
    }
}

async function preview() {
    const amount = document.getElementById("amount").value;
    if (!amount) {
        alert("Enter the amount");
        return;
    }
    try {
        const profitability = await arbitrageContract.methods.previewProfitability(amount).call();
        document.getElementById("result").value = profitability > 0 ? `Profit: ${profitability}` : "Not viable";
    } catch (error) {
        console.error("Error in preview: ", error);
    }
}

async function execute() {
    const amount = document.getElementById("amount").value;
    if (!amount) {
        alert("Enter the amount");
        return;
    }
    try {
        await arbitrageContract.methods.executeArbitrage(amount).send({ from: userAccount });
        alert("Transaction executed!");
    } catch (error) {
        console.error("Error in execution: ", error);
    }
}
