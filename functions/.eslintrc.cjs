module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
  },
  extends: ["google"],
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  rules: {
    quotes: ["error", "double"],
  },
};
