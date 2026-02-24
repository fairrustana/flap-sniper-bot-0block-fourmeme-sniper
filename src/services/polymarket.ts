import axios from "axios";
import type { PolymarketPrices } from "../types";

const POLYMARKET_CLOB_BASE = "https://clob.polymarket.com";

/** Response from POST /prices: keyed by token_id, values in 0-1 */
interface PricesResponse {
  [tokenId: string]: { BUY: number; SELL: number } | undefined;
}

/**
 * Fetch prices for tokens via Polymarket CLOB POST /prices (same as poly-market-bot).
 * More reliable than GET /book which can return 404/400.
 */
async function fetchPrices(
  baseUrl: string,
  tokenUp: string,
  tokenDown: string
): Promise<PricesResponse | null> {
  const base = baseUrl.replace(/\/$/, "");
  const body = [
    { token_id: tokenUp, side: "BUY" as const },
    { token_id: tokenUp, side: "SELL" as const },
  ];
  if (tokenDown.trim() !== "") {
    body.push(
      { token_id: tokenDown, side: "BUY" as const },
      { token_id: tokenDown, side: "SELL" as const }
    );
  }
  try {
    const { data } = await axios.post<PricesResponse>(`${base}/prices`, body, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
    });
    return data;
  } catch (err) {
    const msg = (err as Error).message;
    const status = axios.isAxiosError(err) && err.response ? err.response.status : "";
    console.error("[Polymarket] fetchPrices error:", status ? `${msg} (${status})` : msg);
    return null;
  }
}

/**
 * Get UP and DOWN token prices from Polymarket (POST /prices).
 * BUY = best ask (price to buy); we convert 0-1 to cents (0-100).
 */
export async function getPolymarketPrices(
  clobBase: string,
  tokenUp: string,
  tokenDown: string
): Promise<PolymarketPrices> {
  const base = clobBase || POLYMARKET_CLOB_BASE;
  const prices = await fetchPrices(base, tokenUp, tokenDown);

  let upCents: number | null = null;
  let downCents: number | null = null;

  if (prices && prices[tokenUp]) {
    const buy = prices[tokenUp]!.BUY;
    if (typeof buy === "number" && !Number.isNaN(buy)) {
      upCents = Math.round(buy * 100);
    }
  }
  if (tokenDown.trim() !== "" && prices && prices[tokenDown]) {
    const buy = prices[tokenDown]!.BUY;
    if (typeof buy === "number" && !Number.isNaN(buy)) {
      downCents = Math.round(buy * 100);
    }
  }

  const hasLiquidity = (upCents != null && upCents < 100) || (downCents != null && downCents < 100);

  return {
    upCents,
    downCents,
    hasLiquidity,
    fetchedAt: Date.now(),
  };
}
