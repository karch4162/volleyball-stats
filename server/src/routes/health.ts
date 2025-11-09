import { FastifyInstance, FastifyPluginAsync } from 'fastify';

export const healthRoute: FastifyPluginAsync = async (app: FastifyInstance) => {
  app.get('/health', async () => ({ status: 'ok', service: 'volleyball-stats', timestamp: new Date().toISOString() }));
};
