import parseArgs from "minimist";
import * as fs from "fs";
import { TezosToolkit, MichelsonMap } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";
import { importKey } from "@taquito/signer";
import { Parser } from "@taquito/michel-codec";
import { Tzip16Module } from "@taquito/tzip16";

const argv = parseArgs(process.argv, {
  default: {
    node: "https://mainnet.tezos.marigold.dev",
    indexer: "https://api.better-call.dev/v1",
    network: "mainnet",
  },

  alias: {
    "secret-path": "secret_path",
  },
});

require("dotenv-defaults").config();
const { TEZOS_WALLET_SECRET } = process.env;

let Tezos = new TezosToolkit(`${argv.node}`);
Tezos.addExtension(new Tzip16Module());

const SECRET = (() => {
  if (argv.secret_path) {
    return fs.readFileSync(argv.secret_path);
  } else if (TEZOS_WALLET_SECRET) {
    return TEZOS_WALLET_SECRET;
  } else {
    return false;
  }
})();

async function keySetup() {
  // Setup Key
  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(`${SECRET}`),
  });
  return Tezos;
}

if (argv.faucet) {
  // TestNet Key
  const buf = fs.readFileSync(argv.faucet);
  const stringFromBuffer = Buffer.from(buf).toString("base64");
  const FAUCET_KEY = JSON.parse(stringFromBuffer);
  importKey(
    Tezos,
    FAUCET_KEY.email,
    FAUCET_KEY.password,
    FAUCET_KEY.mnemonic.join(" "),
    FAUCET_KEY.activation_code,
  ).catch((e) => console.error(e));
}

async function readContract(contractName: string) {
  let contracts = fs.readdirSync("michelson");
  let contractTz = fs.readFileSync(
    "michelson/" + contracts[contracts.indexOf(`${contractName}` + ".tz")],
    { encoding: "utf8" },
  );
  const p = new Parser();
  let contract = p.parseScript(contractTz);
  return contract;
}

async function deploy(contractName: string) {
  // const url = 'https://ipfs.io/ipfs/QmaY7Ga724SkP5WRDuyrmvFwpStziB8WEqu24P8UWLxZ44';
  console.log("Deploying contract...");
  const contract = await readContract(contractName);
  if (contract === null) {
    return;
  }
  const metadata = new MichelsonMap();
  const owner = await Tezos.signer.publicKeyHash();
  // metadata.set("", char2Bytes(url));
  Tezos.contract
    .originate({
      code: contract,
      storage: {
        metadata: metadata,
        owner: owner,
      },
    })
    .then((originationOp) => {
      console.log(
        `Waiting for confirmation of origination for ${originationOp.contractAddress}...`,
      );
      return originationOp.contract();
    }) // eslint-disable-next-line no-unused-vars
    .then((_contract) => {
      console.log(
        "Origination completed. Use a chainviewer like https://better-call.dev/ to confirm the KT1 is ready.",
      );
    })
    .catch((error) => console.log(`Error: ${JSON.stringify(error, null, 2)}`));
}

async function run() {
  if (!argv.faucet && SECRET) {
    Tezos = await keySetup();
  }
  const subcommand = argv._[2];
  switch (subcommand) {
    case "test":
      {
        console.log(SECRET);
      }
      break;
    case "deploy":
      {
        // const contractName = argv?._[3];
        const contracts = ["main"];
        const contractName = "main";
        await deploy(contractName);
      }
      break;
    default:
      console.log(`Unrecognized subcommand: '${argv._[2]}'`);
  }
}

run();
