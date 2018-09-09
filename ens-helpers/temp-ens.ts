/**
Imports wont work, needs to be tailored to the project


To calculate signatures, do the following:

  const signature = "......"
  signature = signature.substr(2) // remove 0x
  const r = `0x${signature.slice(0, 64)}`
  const s = `0x${signature.slice(64, 128)}`
  const v = `0x${signature.slice(128, 130)}`
  const vDecimal = web3.utils.toDecimal(v)




---------------------------------
for constructing transactions, do the following:

// code
  const txCount = await web3.eth.getTransactionCount(
    ZINC_ETH_ADDRESS
  )

  const txData = {
    nonce: web3.utils.toHex(txCount),
    gasLimit: web3.utils.toHex(1600000),
    gasPrice: web3.utils.toHex(getGasPrice()),
    from: ZINC_ETH_ADDRESS,
    to: ZINC_ACCESSOR_ADDRESS,
    data
  }
  const privateKey = new Buffer(ZINC_ETH_KEY, "hex")
  const transaction = new tx(txData)
  transaction.sign(privateKey)
  const serializedTx = transaction.serialize().toString("hex")
  const txReceipt = await web3.eth.sendSignedTransaction(`0x${serializedTx}`)
  if (txReceipt.status && txReceipt.transactionHash && txReceipt.logs) {
    for (const log of txReceipt.logs) {
      if (log.topics[0] === eventSha) {
        logger.info(`Contract deployed: ${JSON.stringify(txReceipt)}`)
        return `0x${log.topics[2].slice(-40)}`
      }
    }
    const err = `Failed to find contract address from receipt: ${JSON.stringify(
      txReceipt
    )}`
    logger.errorSOS(err)
    throw new Error(err)
  } else {
    logger.errorSOS(
      `Failed to deploy contract. Receipt: ${JSON.stringify(txReceipt)}`
    )
    throw new Error(txReceipt)
  }
--------------------------------------



**/

import {
  DEFAULT_GAS_LIMIT,
  ENS_REGISTRY_ADDRESS,
  ENS_RESOLVER_ADDRESS,
  ZINC_ETH_ADDRESS
} from "../config/web3.config"
import logger from "../logger"
import { ensRegistry, ensResolver, getGasPrice, web3 } from "./web3-constructor"
import { signTx } from "./web3-write"

/* tslint:disable-next-line:no-var-requires */
const namehash = require("eth-ens-namehash")
/* tslint:disable-next-line:no-var-requires */
const stringPrep = require("node-stringprep").StringPrep
const prep = new stringPrep("nameprep")

export function nameprep(v: string): string {
  return prep.prepare(v)
}

const setSubnodeOwnerTx = (
  sub: string,
  domain: string,
  ownerAdress: string
) => (transactionNonce: number) => {
  const node = namehash.hash(domain)
  const label = web3.utils.sha3(sub)
  const txData = {
    nonce: web3.utils.toHex(transactionNonce),
    gasLimit: web3.utils.toHex(DEFAULT_GAS_LIMIT),
    gasPrice: web3.utils.toHex(getGasPrice()),
    to: ENS_REGISTRY_ADDRESS,
    from: ZINC_ETH_ADDRESS,
    data: ensRegistry.methods
      .setSubnodeOwner(node, label, ownerAdress)
      .encodeABI()
  }
  return signTx(txData)
}

const setResolverTx = (sub: string, domain: string) => (
  transactionNonce: number
) => {
  const txData = {
    nonce: web3.utils.toHex(transactionNonce),
    gasLimit: web3.utils.toHex(DEFAULT_GAS_LIMIT),
    gasPrice: web3.utils.toHex(getGasPrice()),
    to: ENS_REGISTRY_ADDRESS,
    from: ZINC_ETH_ADDRESS,
    data: ensRegistry.methods
      .setResolver(namehash.hash(`${sub}.${domain}`), ENS_RESOLVER_ADDRESS)
      .encodeABI()
  }
  return signTx(txData)
}

const setAddrTx = (sub: string, domain: string, address: string) => (
  transactionNonce: number
) => {
  const txData = {
    nonce: web3.utils.toHex(transactionNonce),
    gasLimit: web3.utils.toHex(DEFAULT_GAS_LIMIT),
    gasPrice: web3.utils.toHex(getGasPrice()),
    to: ENS_RESOLVER_ADDRESS,
    from: ZINC_ETH_ADDRESS,
    data: ensResolver.methods
      .setAddr(namehash.hash(`${sub}.${domain}`), address)
      .encodeABI()
  }
  return signTx(txData)
}

export async function setEnsSubdomain(
  sub: string,
  domain: string,
  address: string,
  ownerAddress: string
) {
  try {
    const prepSub = nameprep(sub)
    const prepDomain = nameprep(domain)
    const setSubnodeOwner = setSubnodeOwnerTx(
      prepSub,
      prepDomain,
      ZINC_ETH_ADDRESS
    )
    const setResolver = setResolverTx(prepSub, prepDomain)
    const setAddr = setAddrTx(prepSub, prepDomain, address)
    const setSubnodeOwnerToUser = setSubnodeOwnerTx(
      prepSub,
      prepDomain,
      ownerAddress
    )

    for (const txCreator of [
      setSubnodeOwner,
      setResolver,
      setAddr,
      setSubnodeOwnerToUser
    ]) {
      const txCount = await web3.eth.getTransactionCount(
        ZINC_ETH_ADDRESS,
        "pending"
      )
      const tx = txCreator(txCount)
      const txReceipt = await web3.eth.sendSignedTransaction(tx)
      if (!txReceipt.status || !txReceipt.transactionHash) {
        logger.errorSOS(`TX failed: ${JSON.stringify(txReceipt)}`)
        throw new Error(`set ENS subdomain failed`)
      }
    }
    logger.info(`ENS name: ${sub} set to ${address}`)
  } catch (e) {
    throw new Error(`set ENS subdomain failed. See error: ${e}`)
  }
}

export async function resolveEnsName(sub: string, domain: string) {
  const node = namehash.hash(`${nameprep(sub)}.${nameprep(domain)}`)
  return ensResolver.methods.addr(node).call({})
}

export async function checkIfEnsNameIsAvailable(sub: string, domain: string) {
  const resolved = await resolveEnsName(nameprep(sub), nameprep(domain))
  return {
    address: resolved,
    available: resolved === "0x0000000000000000000000000000000000000000"
  }
}
