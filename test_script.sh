sleep 5
if curl api:3000 | grep -q 'Fakta hari ini adalah'; then
  echo "Tests passed!"
  exit 0
else
  echo "Tests failed!"
  exit 1
fi