import logger from './logger.js';
import { initTokenManagerClient } from './token-manager-client.ts';

// 初始化 Token Manager 客户端
const tokenManagerEnabled = process.env.TOKEN_MANAGER_ENABLED === 'true';
const tokenManagerUrl = process.env.TOKEN_MANAGER_URL;
const tokenManagerApiKey = process.env.TOKEN_MANAGER_API_KEY;

if (tokenManagerEnabled) {
  initTokenManagerClient(tokenManagerUrl, tokenManagerApiKey);
  logger.info('Token Manager 已启用');
} else {
  logger.info('Token Manager 未启用，使用静态 SessionID 模式');
}

// 允许无限量的监听器
process.setMaxListeners(Infinity);
// 输出未捕获异常
process.on("uncaughtException", (err, origin) => {
    logger.error(`An unhandled error occurred: ${origin}`, err);
});
// 输出未处理的Promise.reject
process.on("unhandledRejection", (_, promise) => {
    promise.catch(err => logger.error("An unhandled rejection occurred:", err));
});
// 输出系统警告信息
process.on("warning", warning => logger.warn("System warning: ", warning));
// 进程退出监听
process.on("exit", () => {
    logger.info("Service exit");
    logger.footer();
});
// 进程被kill
process.on("SIGTERM", () => {
    logger.warn("received kill signal");
    process.exit(2);
});
// Ctrl-C进程退出
process.on("SIGINT", () => {
    process.exit(0);
});