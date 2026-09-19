import {Miniflare} from 'miniflare';
import {readFileSync,readdirSync,existsSync,mkdirSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import {parse} from 'dotenv';
if(!existsSync('dist/server/index.js'))throw new Error('Build first: npm run build');
mkdirSync('.sites-runtime',{recursive:true});
const secretFile='.sites-runtime/otp-secret';if(!existsSync(secretFile))writeFileSync(secretFile,randomBytes(32).toString('hex'),{mode:0o600});
const bindings={DEMO_MODE:'true',OTP_SIGNING_SECRET:readFileSync(secretFile,'utf8'),...(existsSync('.dev.vars')?parse(readFileSync('.dev.vars')):{})};
const mf=new Miniflare({host:'127.0.0.1',port:Number(process.env.PORT)||5173,modules:[{type:'ESModule',path:resolve('dist/server/index.js')},...readdirSync('dist/server',{recursive:true}).filter(f=>f.endsWith('.js')&&f!=='index.js').map(f=>({type:'ESModule',path:resolve('dist/server',f)}))],modulesRoot:resolve('dist/server'),compatibilityDate:'2026-05-15',compatibilityFlags:['nodejs_compat'],cf:false,d1Databases:{DB:'00000000-0000-4000-8000-000000000000'},d1Persist:'.wrangler/state/v3/d1',r2Buckets:{BUCKET:'site-creator-r2'},r2Persist:'.wrangler/state/v3/r2',bindings,assets:{directory:resolve('dist/client'),binding:'ASSETS',routerConfig:{has_user_worker:true}}});
const db=await mf.getD1Database('DB');
await db.prepare('CREATE TABLE IF NOT EXISTS local_migrations (name TEXT PRIMARY KEY)').run();
for(const file of readdirSync('drizzle').filter(f=>f.endsWith('.sql')).sort()){
 if(await db.prepare('SELECT name FROM local_migrations WHERE name=?').bind(file).first())continue;
 const statements=readFileSync('drizzle/'+file,'utf8').split('--> statement-breakpoint').map(s=>s.trim()).filter(Boolean).map(s=>db.prepare(s));
 await db.batch([...statements,db.prepare('INSERT INTO local_migrations (name) VALUES (?)').bind(file)]);
}
console.log(`LPU Campus App: ${await mf.ready}`);
console.log('Local database and media persist in .wrangler/state.');
process.on('SIGINT',async()=>{await mf.dispose();process.exit(0);});
process.on('SIGTERM',async()=>{await mf.dispose();process.exit(0);});
