
if ($1 === 'block') {
  $$ = { type: 'block' }
}
else {
  $$ = { type: $1 }
}