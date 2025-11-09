import Fastify from 'fastify';
import cors from '@fastify/cors';
import { healthRoute } from './routes/health.js';

async function bootstrap() {
  const server = Fastify({ logger: true });
  await server.register(cors, { origin: true });
  await server.register(healthRoute);

  const port = Number(process.env.PORT ?? 3333);
  try {
    await server.listen({ port, host: '0.0.0.0' });
    console.log(`API listening on port ${port}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

bootstrap();
