import { assert, expect } from "chai";
import hre from "hardhat";

const uniswapRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const sushiswapRouter = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
const departmentOfGovernmentEffeiciency =
  "0x1121AcC14c63f3C872BFcA497d10926A6098AAc5";
const usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

describe("@/contract/BasicArbitrage", () => {
  async function deploy() {
    const [owner] = await hre.ethers.getSigners();
    const BasicArbitrage = await hre.ethers.getContractFactory(
      "BasicArbitrage"
    );
    const arbitrage = await BasicArbitrage.connect(owner).deploy();
    // const BasicArbitrage = await hre.ethers.getContractAt(
    //   "BasicArbitrage",
    //   "0x5FbDB2315678afecb367f032d93F642f64180aa3"
    // );
    // console.log("컨트랙트 가져오기 성공");
    await arbitrage.waitForDeployment();
    return { arbitrage };
  }

  it("컨트랙트에 초기 금액을 예치할 수 있다.", async () => {
    const [owner] = await hre.ethers.getSigners();
    const { arbitrage } = await deploy();
    const initialEth = hre.ethers.parseEther("1");

    const tx = await owner.sendTransaction({
      to: await arbitrage.getAddress(),
      value: initialEth,
    });
    await tx.wait();

    const balance = await arbitrage.getBalance();
    expect(balance).equal(initialEth);
  });

  it("withdraw를 통해 예치한 금액을 찾을 수 있다.", async () => {
    const [owner] = await hre.ethers.getSigners();
    const { arbitrage } = await deploy();
    const initialEth = hre.ethers.parseEther("1");

    const tx = await owner.sendTransaction({
      to: await arbitrage.getAddress(),
      value: initialEth,
    });
    await tx.wait();

    const balance = await owner.provider.getBalance(owner.address);

    await arbitrage.withdraw(owner.address);

    expect(
      (await owner.provider.getBalance(owner.address)) > balance,
      "withdraw is not working well"
    );
  });

  it("estimateProfit을 통해 예상 수익을 확인할 수 있다.", async () => {
    const { arbitrage } = await deploy();
    const estinmatedProfit = await arbitrage.estimateProfit(
      departmentOfGovernmentEffeiciency,
      usdt,
      uniswapRouter,
      sushiswapRouter,
      hre.ethers.parseEther("1.0")
    );
    console.log(estinmatedProfit);

    assert(estinmatedProfit, "Cannot find value");
  });
});
