// This example shows how to make a call to an open API (no authentication required)
// to retrieve asset price from a symbol(e.g., ETH) to another symbol (e.g., USD)

// CryptoCompare API https://min-api.cryptocompare.com/documentation?key=Price&cat=multipleSymbolsFullPriceEndpoint

// Refer to https://github.com/smartcontractkit/functions-hardhat-starter-kit#javascript-code

// Arguments can be provided when a request is initated on-chain and used in the request source code as shown below
const videoId = args[0]


if (
  secrets.apiKey == "" ||
  secrets.apiKey === "Your coinmarketcap API key (get a free one: https://coinmarketcap.com/api/)"
) {
  throw Error(
    "YT_API_KEY environment variable not set for Youtube API."
  )
}

// make HTTP request
const url = `https://www.googleapis.com/youtube/v3/videos`
const part = "statistics"

// construct the HTTP Request object. See: https://github.com/smartcontractkit/functions-hardhat-starter-kit#javascript-code
// params used for URL query parameters
// Example of query: https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD
const getViewsRequest = Functions.makeHttpRequest({
  url: url,
  params: {
    id: videoId,
    key: secrets.apiKey,
    part: part,
  },
})

const getViewsResponse = await getViewsRequest
if (getViewsResponse.error) {
  console.error(getViewsResponse.error)
  throw Error("Request failed")
}

const data = getViewsResponse["data"]
if (data.Response === "Error") {
  console.error(data.Message)
  throw Error(`Functional error. Read message: ${data.Message}`)
}

const views = parseInt(data.items[0].statistics.viewCount)


return Functions.encodeUint256(views)

