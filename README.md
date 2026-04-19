# LE-MOVIE 🎬

A premium, highly-responsive Flutter Web application serving as a modern streaming platform. This project recreates the smooth, high-fidelity experience of Netflix and Fmovies with a fully responsive architecture, working perfectly on vast Desktop monitors and mobile screens alike.

## ✨ Features

- **Premium UI/UX:** Dark-mode primary aesthetic with Netflix-style carousels, responsive grid layouts, and glassmorphic UI elements.
- **Responsive Architecture (`Desktop-First`):** Uses clamped BoxConstraints, adaptive Grid delegates, and flexible row wraps to ensure the UI looks incredible on 4K Desktop monitors, laptops, and mobile devices. 
- **10+ Streaming Server Options:** Directly scrapes and interfaces with Fmovies embed providers. Features robust streaming from platforms such as:
  - UltraBox (`player.vidplus.to`)
  - NexaStream / HyperLink (`vidsrc.wtf`)
  - CloudBox (`vidify.top`)
  - UpCloud (`player.vidsrc.co`)
  - StreamBoxHD, MovieVault, MediaHub, and more!
- **Universal Smart Search:** Type-ahead, debounced search API covering both Movies and TV series with visual dropdown suggestions.
- **Dynamic Content Discovery:** Uses `db.videasy.net` metadata architecture to source trending movies, top-rated shows, backdrops, cast, and detailed season/episode configurations.
- **CORS Bypass Tactics:** Implements precise HTTP header spoofing (`Origin`, `Referer`, `Sec-Fetch-*`) natively in Dart via `dio` to cleanly interface with protected provider endpoints.

## 🚀 Tech Stack

- **Frontend:** Flutter SDK (Web)
- **State Management:** `provider`
- **Network Layer:** `dio` 
- **UI Libraries:** `shimmer`, `cached_network_image`
- **CI/CD Deployment:** GitHub Actions automatically builds release packages targeted via `npx wrangler` directly to Cloudflare Pages.

## 📦 Getting Started

### Prerequisites
- Flutter SDK (`>= 3.0.0`)
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Ansh7473/LE-MOVIE.git
   cd LE-MOVIE
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run locally (Chrome or Web server):
   ```bash
   flutter run -d chrome
   ```

## ☁️ Deployment Pipeline

This repository is configured with a fully automated CI/CD pipeline using **GitHub Actions**.

Target Branch: `main`

Every push to `main` triggers:
1. Flutter environment configuration.
2. Web production build compilation (`flutter build web --release`).
3. Zero-downtime deployment directly to Cloudflare Pages using Wrangler auth via Cloudflare API Secrets.

## 🛠️ Disclaimer
*This project is built for educational and development portfolio purposes to demonstrate advanced cross-origin handling, Flutter UI/UX architecture, and CI/CD pipelines.*
