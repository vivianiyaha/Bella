import streamlit as st
from web3 import Web3
import json

# Access secrets securely
API_KEY = st.secrets["API_KEY"]
PRIVATE_KEY = st.secrets["PRIVATE_KEY"]
WALLET_ADDRESS = st.secrets["WALLET_ADDRESS"]

# Connect to Binance Smart Chain (BSC) via an Infura or public RPC URL
bsc_rpc_url = "https://bsc-dataseed.binance.org/"
w3 = Web3(Web3.HTTPProvider(bsc_rpc_url))

# Deployed contract address (replace with actual contract address)
contract_address = "0xYourContractAddressHere"

# ABI of the contract (replace with actual ABI from your deployment)
contract_abi = json.loads('[{"constant":true,"inputs":[],"name":"checkLiquidity","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"}]')

# Connect to the contract
contract = w3.eth.contract(address=contract_address, abi=contract_abi)

# Function to check liquidity using Web3
def check_liquidity(token_address, amount):
    try:
        result = contract.functions.checkLiquidity(token_address, amount).call()
        return result
    except Exception as e:
        st.error(f"Error checking liquidity: {e}")
        return False

# Streamlit interface
def main():
    st.title("Trading Bot Smart Contract Interface")

    # Display the wallet balance
    balance = w3.eth.get_balance(WALLET_ADDRESS)
    st.sidebar.subheader("Account Info")
    st.sidebar.write(f"BNB Balance: {w3.fromWei(balance, 'ether')} BNB")
    
    st.sidebar.write(f"Contract Address: {contract_address}")
    
    # Liquidity and Honeypot Check
    st.subheader("Liquidity and Honeypot Check")
    token_address = st.text_input("Token Address", "0xTokenAddressHere")
    amount = st.number_input("Amount", min_value=0.1, step=0.1)

    if st.button('Check Liquidity'):
        if token_address and amount:
            is_liquid = check_liquidity(token_address, amount)
            if is_liquid:
                st.success("Liquidity is sufficient for the trade.")
            else:
                st.error("Insufficient liquidity for the trade.")

    # Trading Control
    st.subheader("Trading Control")

    if st.button('Start Trading'):
        st.info("Starting the trading bot...")
        # Add logic to interact with contract for starting the trade

    if st.button('Stop Trading'):
        st.info("Stopping the trading bot...")
        # Add logic to interact with contract for stopping the trade

    st.subheader("Withdraw Funds")

    # Withdrawal functionality for the contract owner
    withdraw_address = st.text_input("Withdraw To Address", "0xRecipientAddressHere")
    withdraw_amount = st.number_input("Withdraw Amount", min_value=0.1, step=0.1)

    if st.button('Withdraw Funds'):
        if withdraw_address and withdraw_amount > 0:
            try:
                # Make the withdrawal transaction (sign and send)
                transaction = contract.functions.withdrawFunds(withdraw_address, withdraw_amount).buildTransaction({
                    'chainId': 56,  # BSC Mainnet
                    'gas': 2000000,
                    'gasPrice': w3.toWei('5', 'gwei'),
                    'nonce': w3.eth.getTransactionCount(WALLET_ADDRESS),
                })
                signed_tx = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY)
                tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
                st.success(f"Withdrawal successful! TX Hash: {tx_hash.hex()}")
            except Exception as e:
                st.error(f"Error during withdrawal: {e}")

if __name__ == "__main__":
    main()
