{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;

  familyPage = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Home</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
        }

        .container {
          display: flex;
          gap: 2rem;
          padding: 2rem;
          flex-wrap: wrap;
          justify-content: center;
          max-width: 900px;
        }

        .tile {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          width: 200px;
          height: 200px;
          border-radius: 20px;
          text-decoration: none;
          color: white;
          transition: transform 0.2s, box-shadow 0.2s;
          box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }

        .tile:hover {
          transform: translateY(-8px);
          box-shadow: 0 20px 40px rgba(0,0,0,0.4);
        }

        .tile-icon {
          font-size: 4rem;
          margin-bottom: 1rem;
        }

        .tile-label {
          font-size: 1.3rem;
          font-weight: 600;
        }

        .tile-watch {
          background: linear-gradient(135deg, #a855f7 0%, #7c3aed 100%);
        }

        .tile-request {
          background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
        }

        .tile-unblock {
          background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        }

        @media (max-width: 600px) {
          .tile {
            width: 160px;
            height: 160px;
          }
          .tile-icon { font-size: 3rem; }
          .tile-label { font-size: 1.1rem; }
          .container { gap: 1.5rem; }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <a href="https://jellyfin.${secrets.domain}" class="tile tile-watch">
          <span class="tile-icon">▶</span>
          <span class="tile-label">Watch</span>
        </a>
        <a href="https://requests.${secrets.domain}" class="tile tile-request">
          <span class="tile-icon">+</span>
          <span class="tile-label">Request</span>
        </a>
        <a href="https://adguard.${secrets.domain}" class="tile tile-unblock">
          <span class="tile-icon">🛡</span>
          <span class="tile-label">Unblock Site</span>
        </a>
      </div>
    </body>
    </html>
  '';
in
{
  # Serve the family landing page via nginx
  services.nginx = {
    enable = true;

    virtualHosts."family-landing" = {
      listen = [{ addr = "127.0.0.1"; port = 8083; }];
      root = familyPage;
      locations."/" = {
        index = "index.html";
        tryFiles = "$uri $uri/ /index.html";
      };
    };
  };
}
