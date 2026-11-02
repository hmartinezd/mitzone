// Import-map replacement used only by the offline contract test.
export const auth = { valid: true, calls: 0, authorization: "" };
export function createClient(_url: string, _key: string, options: {
  global: { headers: { Authorization: string } };
}) {
  auth.authorization = options.global.headers.Authorization;
  return {
    auth: {
      getUser() {
        auth.calls++;
        return Promise.resolve({
          data: { user: auth.valid ? { id: "test-user" } : null },
        });
      },
    },
  };
}
