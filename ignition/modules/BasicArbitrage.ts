import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BasicArbitrage = buildModule("BasicArbitrageModule", (m) => {
  const basicArbitrage = m.contract("BasicArbitrage");
  return { basicArbitrage };
});

export default BasicArbitrage;
