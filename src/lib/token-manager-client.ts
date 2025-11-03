import axios, { AxiosInstance } from 'axios';
import logger from './logger.ts';

interface SessionInfo {
  sessionId: string;
  email: string;
  expiresAt: string;
  isUS: boolean;
}

interface TokenManagerStats {
  total: number;
  available: number;
  unavailable: number;
  cn: {
    total: number;
    available: number;
  };
  us: {
    total: number;
    available: number;
  };
}

/**
 * Token Manager 客户端
 * 用于从 Dreamina-Token-Manager 服务获取 SessionID
 */
export class TokenManagerClient {
  private client: AxiosInstance;
  private baseURL: string;
  private apiKey: string;
  private enabled: boolean;

  constructor(baseURL?: string, apiKey?: string) {
    this.enabled = !!baseURL && !!apiKey;
    this.baseURL = baseURL || '';
    this.apiKey = apiKey || '';

    if (!this.enabled) {
      logger.warn('Token Manager 未配置，将使用静态 SessionID');
      return;
    }

    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: 10000,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
    });

    logger.success(`Token Manager 客户端初始化成功: ${this.baseURL}`);
  }

  /**
   * 检查是否启用 Token Manager
   */
  isEnabled(): boolean {
    return this.enabled;
  }

  /**
   * 获取可用的 SessionID
   * @param isUS 是否获取国际版账户
   * @returns SessionID 信息
   */
  async acquireSessionId(isUS: boolean = false): Promise<SessionInfo | null> {
    if (!this.enabled) {
      logger.warn('Token Manager 未启用，无法获取 SessionID');
      return null;
    }

    try {
      const response = await this.client.get<SessionInfo>('/api/sessionid/acquire', {
        params: { isUS: isUS ? 'true' : 'false' },
      });

      const sessionInfo = response.data;
      logger.info(`从 Token Manager 获取 SessionID: ${sessionInfo.email} (${isUS ? 'US' : 'CN'})`);

      return sessionInfo;
    } catch (error: any) {
      if (error.response) {
        const status = error.response.status;
        const message = error.response.data?.message || error.message;

        if (status === 401) {
          logger.error('Token Manager API Key 无效');
        } else if (status === 503) {
          logger.error(`Token Manager 没有可用的${isUS ? '国际版' : '国内版'}账户`);
        } else {
          logger.error(`Token Manager 请求失败: ${message}`);
        }
      } else {
        logger.error(`Token Manager 连接失败: ${error.message}`);
      }

      return null;
    }
  }

  /**
   * 获取 Token Manager 统计信息
   * @returns 统计信息
   */
  async getStats(): Promise<TokenManagerStats | null> {
    if (!this.enabled) {
      return null;
    }

    try {
      const response = await this.client.get<TokenManagerStats>('/api/sessionid/stats');
      return response.data;
    } catch (error: any) {
      logger.error(`获取 Token Manager 统计信息失败: ${error.message}`);
      return null;
    }
  }

  /**
   * 健康检查
   * @returns 是否健康
   */
  async healthCheck(): Promise<boolean> {
    if (!this.enabled) {
      return false;
    }

    try {
      const stats = await this.getStats();
      if (!stats) {
        return false;
      }

      const hasAvailable = stats.available > 0;
      if (!hasAvailable) {
        logger.warn('Token Manager 没有可用的账户');
      }

      return hasAvailable;
    } catch (error) {
      return false;
    }
  }
}

// 导出单例实例
let tokenManagerClient: TokenManagerClient | null = null;

export function initTokenManagerClient(baseURL?: string, apiKey?: string): TokenManagerClient {
  if (!tokenManagerClient) {
    tokenManagerClient = new TokenManagerClient(baseURL, apiKey);
  }
  return tokenManagerClient;
}

export function getTokenManagerClient(): TokenManagerClient | null {
  return tokenManagerClient;
}
