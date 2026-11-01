import { Application } from 'express';
import type { Server as HTTPServer } from 'http';
import { createApp } from './app';
import { config } from './config/config';

class Server {
  public app: Application;
  private port: number;
  private httpServer?: HTTPServer;

  constructor() {
    this.app = createApp();
    this.port = config.port;
  }

  public async listen(): Promise<void> {
    try {
      this.httpServer = this.app.listen(this.port, () => {
        console.log(`Server running on port ${this.port} in ${config.env} mode`);
        console.log(`Health check available at: http://localhost:${this.port}/health`);
        console.log(`API endpoints available at: http://localhost:${this.port}${config.apiPrefix}`);
      });
    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  public async close(): Promise<void> {
    if (this.httpServer) {
      return new Promise((resolve, reject) => {
        this.httpServer?.close((err: Error | unknown) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    }
  }
}

const server = new Server();
server.listen();

export default server;
