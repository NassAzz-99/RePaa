import { env } from './config/env.js';
import app from './app.js';

app.listen(env.PORT, env.HOST, () => {
  console.log(`✅ Server berjalan di http://${env.HOST}:${env.PORT}/api`);
  console.log(`   Emulator Android: http://10.0.2.2:${env.PORT}/api`);
  console.log(`   Timezone bisnis : Asia/Jakarta`);
});
