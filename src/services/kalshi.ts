import axios from "axios";
import type { KalshiPrices } from "../types";

const KALSHI_MAIN_BASE = "https://api.kalshi.com/trade-api/v2";
const KALSHI_ELECTIONS_BASE = "https://api.elections.kalshi.com/trade-api/v2";

interface KalshiOrderbookResponse {
  orderbook?: {
    yes: [number, number][]; // [price_cents, quantity] or [price, size]
    no: [number, number][];
  };
}

interface KalshiMarketResponse {
  market?: {
    status?: string;
    ticker?: string;
    /** YES best bid in dollars (e.g. "0.56") */
    yes_bid_dollars?: string;
    /** YES best ask in dollars */
    yes_ask_dollars?: string;
    no_bid_dollars?: string;
    no_ask_dollars?: string;
  };
}

function bestBidCents(levels: [number, number][] | undefined): number | null {
  if (!levels || levels.length === 0) return null;
  const price = levels[levels.length - 1][0];
  return typeof price === "number" && !Number.isNaN(price) ? price : null;
}

/** Parse dollar string (e.g. "0.56") to cents */
function dollarsToCents(dollars: string | undefined): number | null {
  if (dollars == null || dollars === "") return null;
  const n = parseFloat(dollars);
  if (Number.isNaN(n)) return null;
  return Math.round(n * 100);
}

async function fetchOrderbook(
  apiBase: string,
  ticker: string
): Promise<{ data: KalshiOrderbookResponse | null; status?: number }> {
  const url = `${apiBase.replace(/\/$/, "")}/markets/${encodeURIComponent(ticker)}/orderbook`;
  try {
    const { data, status } = await axios.get<KalshiOrderbookResponse>(url, { timeout: 10000 });
    return { data, status };
  } catch (err) {
    const status = axios.isAxiosError(err) && err.response ? err.response.status : undefined;
    return { data: null, status };
  }
}

async function fetchMarket(
  apiBase: string,
  ticker: string
): Promise<{ data: KalshiMarketResponse | null; status?: number }> {
  const url = `${apiBase.replace(/\/$/, "")}/markets/${encodeURIComponent(ticker)}`;
  try {
    const { data, status } = await axios.get<KalshiMarketResponse>(url, { timeout: 10000 });
    return { data, status };
  } catch (err) {
    const status = axios.isAxiosError(err) && err.response ? err.response.status : undefined;
    return { data: null, status };
  }
}

let lastKalshi404Log = 0;
const KALSHI_404_LOG_INTERVAL_MS = 60_000;

/**
 * Get Kalshi YES/NO prices and market status.
 * Tries the configured apiBase first; if 404, tries the other Kalshi base (main vs elections).
 * Uses GET /markets/{ticker} for status and optional price fallback (yes_bid_dollars); uses orderbook when available.
 */
export async function getKalshiPrices(
  apiBase: string,
  ticker: string
): Promise<KalshiPrices> {
  const base = apiBase.replace(/\/$/, "");
  const [bookResult, marketResult] = await Promise.all([
    fetchOrderbook(base, ticker),
    fetchMarket(base, ticker),
  ]);

  let orderbook = bookResult.data?.orderbook;
  let market = marketResult.data?.market;

  if ((bookResult.status === 404 || marketResult.status === 404) && !market && !orderbook) {
    const otherBase =
      base.startsWith("https://api.kalshi.com")
        ? KALSHI_ELECTIONS_BASE
        : KALSHI_MAIN_BASE;
    const [fallbackBook, fallbackMarket] = await Promise.all([
      fetchOrderbook(otherBase, ticker),
      fetchMarket(otherBase, ticker),
    ]);
    if (fallbackMarket.data?.market || fallbackBook.data?.orderbook) {
      market = fallbackMarket.data?.market ?? market;
      orderbook = fallbackBook.data?.orderbook ?? orderbook;
    }
    if (!market && !orderbook && Date.now() - lastKalshi404Log > KALSHI_404_LOG_INTERVAL_MS) {
      lastKalshi404Log = Date.now();
      console.warn(
        "[Kalshi] Market not found (404). Ticker may be expired or wrong. Try a current ticker or switch KALSHI_API_BASE (elections: api.elections.kalshi.com, main: api.kalshi.com)."
      );
    }
  }

  let yesCents: number | null = null;
  let noCents: number | null = null;

  if (orderbook) {
    yesCents = bestBidCents(orderbook.yes);
    noCents = bestBidCents(orderbook.no);
  }
  if (yesCents == null && market?.yes_bid_dollars != null) {
    yesCents = dollarsToCents(market.yes_bid_dollars);
  }
  if (noCents == null && market?.no_bid_dollars != null) {
    noCents = dollarsToCents(market.no_bid_dollars);
  }

  const status = market?.status ?? "unknown";
  const isFinished = status === "closed" || status === "settled" || status === "finalized";

  return {
    yesCents,
    noCents,
    status,
    isFinished,
    fetchedAt: Date.now(),
  };
}
