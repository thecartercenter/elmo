import isEmpty from "lodash/isEmpty";
import queryString from "query-string";

const MAX_HINTS_BEFORE_ELLIPSIZE = 1;

/**
 * Stringified controller_name from Rails.
 */
export const CONTROLLER_NAME = {
  RESPONSES: "\"responses\"",
};

/**
 * Given a list of hints (e.g. currently selected form names for the form filter button),
 * stringify them to be displayed on the button itself.
 */
export function getButtonHintString(hints) {
  if (isEmpty(hints)) {
    return "";
  }

  const joinedHints = hints.length > MAX_HINTS_BEFORE_ELLIPSIZE
    ? hints.length
    : hints.join(", ");

  return ` (${joinedHints})`;
}

/**
 * Given a form ID, find it in the list of all forms and return the name.
 */
export function getFormNameFromId(allForms, searchId) {
  const form = allForms.find(({id}) => searchId === id);
  return (form && form.name) || "Unknown";
}

/**
 * Given all of the different filter states,
 * return a stringified version for the backend.
 */
export function getFilterString(allForms, {selectedFormIds, advancedSearchText}) {
  const selectedFormNames = selectedFormIds
    .map((id) => JSON.stringify(getFormNameFromId(allForms, id)));

  const parts = [
    isEmpty(selectedFormNames) ? null : `form:(${selectedFormNames.join("|")})`,
    advancedSearchText,
  ].filter(Boolean);

  return parts.join(" ");
}

/**
 * Reload the page with the given search.
 */
export function submitSearch(filterString) {
  const parsed = queryString.parse(window.location.search);
  // The `search` query param will be removed from the URL if it's `undefined`.
  const search = filterString || undefined;
  const params = queryString.stringify({...parsed, search});

  window.location.assign(params
    ? `?${params}`
    : window.location.pathname);
}

/**
 * Returns true if the given param name exists and is non-empty.
 */
export function isQueryParamTruthy(paramName) {
  const parsed = queryString.parse(window.location.search);
  return Boolean(parsed[paramName]);
}