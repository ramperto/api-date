sleep 5
if curl api:8080/users/1 | grep -q 'bob'; then
  echo "Tests passed!"
  exit 0
else
  echo "Tests failed!"
  exit 1
fi