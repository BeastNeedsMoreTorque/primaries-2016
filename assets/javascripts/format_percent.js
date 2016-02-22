/**
 * Converts 13.22123 to "13.2"
 */
function format_percent(n) {
  return n.toFixed(1);
}

/**
 * Converts 13.22123 to "13"
 *
 * Rounds to the nearest integer. Special values "<1" and ">99" help clarify
 * that "0" and "100" are exact.
 */
function format_percent_int(n) {
  if (n == 0) {
    return '0';
  } else if (n == 100) {
    return '100';
  } else if (n < 1) {
    return '<1';
  } else if (n > 99) {
    return '>99';
  } else {
    return n.toFixed(0);
  }
}
