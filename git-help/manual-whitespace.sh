sed -i.bak 's/\t/    /g' chat.sol
sed -i.bak -E 's/[[:space:]]*$//' chat.sol
git add chat.sol
