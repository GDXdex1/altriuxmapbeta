import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { ResponseLogger } from "@/components/response-logger";
import { cookies } from "next/headers";
import { ReadyNotifier } from "@/components/ready-notifier";
import { Providers } from "./providers";
import FarcasterWrapper from "@/components/FarcasterWrapper";

const geistSans = localFont({
  src: "./fonts/GeistVF.woff",
  variable: "--font-geist-sans",
  weight: "100 900",
});
const geistMono = localFont({
  src: "./fonts/GeistMonoVF.woff",
  variable: "--font-geist-mono",
  weight: "100 900",
});

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookieStore = await cookies();
  const requestId = cookieStore.get("x-request-id")?.value;

  return (
    <html lang="en">
      <head>
        {requestId && <meta name="x-request-id" content={requestId} />}
        <link rel="icon" href="https://careful-lavender-rabbit.myfilebase.com/ipfs/QmaLfvBSTQgtBfj4GQhQnP5jQzhPivCmMPb7q4J2navHwT" sizes="any" />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {/* Do not remove this component, we use it to notify the parent that the mini-app is ready */}
        <ReadyNotifier />
        <Providers>
          <FarcasterWrapper>
            {children}
          </FarcasterWrapper>
        </Providers>
        <ResponseLogger />
      </body>
    </html>
  );
}

export const metadata: Metadata = {
  title: "Drariux Network - Altriux World",
  description: "Explore the decentralized world on Sui blockchain. Build your empire, trade resources, and conquer territories in Altriux World and Salom Feudal.",
  manifest: "/manifest.json",
  themeColor: "#3b82f6",
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 1,
    userScalable: false
  },
  other: {
    "fc:frame": JSON.stringify({ "version": "next", "imageUrl": "https://usdozf7pplhxfvrl.public.blob.vercel-storage.com/thumbnail_82ebd1e2-3510-4414-9313-b9fccbffab66-tNDzQNt50WUhUncbOD6gWhgUoHpzwo", "button": { "title": "Open with Ohara", "action": { "type": "launch_frame", "name": "Drariux Network", "url": "https://mixture-cannot-242.app.ohara.ai", "splashImageUrl": "https://usdozf7pplhxfvrl.public.blob.vercel-storage.com/farcaster/splash_images/splash_image1.svg", "splashBackgroundColor": "#ffffff" } } }
    )
  }
};
