import {Miniflare} from 'miniflare';
import {testCareer} from './career.mjs';
import {testCareerBrowser} from './career-browser.mjs';
import {readFileSync,readdirSync,mkdtempSync} from 'node:fs';
import {resolve} from 'node:path';
import {tmpdir} from 'node:os';
import assert from 'node:assert/strict';
const state=mkdtempSync(resolve(tmpdir(),'lpu-db-test-'));
const options={host:'127.0.0.1',port:0,modules:[{type:'ESModule',path:resolve('dist/server/index.js')},...readdirSync('dist/server',{recursive:true}).filter(f=>f.endsWith('.js')&&f!=='index.js').map(f=>({type:'ESModule',path:resolve('dist/server',f)}))],modulesRoot:resolve('dist/server'),compatibilityDate:'2026-05-15',compatibilityFlags:['nodejs_compat'],cf:false,d1Databases:['DB'],d1Persist:state+'/d1',r2Buckets:['BUCKET'],r2Persist:state+'/r2',bindings:{DEMO_MODE:'true',OTP_SIGNING_SECRET:'automated-test-secret-not-for-production'},assets:{directory:resolve('dist/client'),binding:'ASSETS',routerConfig:{has_user_worker:true}}};
let mf=new Miniflare(options);
async function request(path,{cookie='',method='GET',body,status=200}={}){const r=await mf.dispatchFetch('http://localhost'+path,{method,headers:{...(cookie?{Cookie:cookie}:{}),...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});const txt=await r.text();let data;try{data=JSON.parse(txt);}catch{throw new Error(path+': '+r.status+' '+txt.slice(0,200));}assert.equal(r.status,status,path+' '+JSON.stringify(data));return {data,cookie:r.headers.get('set-cookie')?.split(';')[0]};}
try{
 let db=await mf.getD1Database('DB');
 for(const f of readdirSync('drizzle').filter(f=>f.endsWith('.sql')).sort())await db.batch(readFileSync('drizzle/'+f,'utf8').split('--> statement-breakpoint').map(s=>s.trim()).filter(Boolean).map(s=>db.prepare(s)));
 await request('/api/auth');
 const password='MyAccount!Pass2026';
 const signup=(email,status=201)=>request('/api/auth',{method:'POST',status,body:{action:'signup',email,password,collegeRegistration:'REG-'+email.replace(/[^a-zA-Z0-9]/g,'').slice(0,30),fullName:'Signup Student',course:'BCA',academicYear:1,gender:'prefer_not_to_say'}});
 const login=(email,status=200,pw=password)=>request('/api/auth',{method:'POST',status,body:{action:'password-login',email,password:pw}});
 let a=await signup('First@Example.com'),b=await signup('second@campus.ac.in');
 assert.notEqual(a.data.user.id,b.data.user.id);assert.equal(a.data.user.email,'first@example.com');assert.equal(a.data.user.mobile,null);assert.equal(a.data.user.isDemo,false);assert.equal(a.data.user.contactKey,undefined);
 assert.equal((await signup('FIRST@example.com',409)).cookie,undefined);
 await login('first@example.com',401,'incorrect');
 await request('/api/auth',{method:'POST',status:404,body:{action:'demo-login',userId:a.data.user.id}});
 await request('/api/auth',{method:'POST',status:403,body:{action:'request-otp',kind:'email',identifier:'second@campus.ac.in'}});
 await request('/api/preferences',{cookie:a.cookie,method:'PUT',body:{key:'goals',value:['Account A only'],version:-1}});
 assert.equal((await request('/api/preferences?key=goals',{cookie:b.cookie})).data.value,null);
 await request('/api/auth',{cookie:a.cookie,method:'POST',body:{action:'logout'}});
 await request('/api/me',{cookie:a.cookie,status:401});a=await login('FIRST@example.com');
 assert.deepEqual((await request('/api/preferences?key=goals',{cookie:a.cookie})).data.value,['Account A only']);
 // Repeat race without relying on which request wins.
 const races=await Promise.all([1,2].map(()=>mf.dispatchFetch('http://localhost/api/auth',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'signup',email:'race2@example.com',collegeRegistration:'RACE-REG2',password,fullName:'Race Student',course:'BCA',academicYear:1,gender:'prefer_not_to_say'})})));
 assert.deepEqual(races.map(r=>r.status).sort(),[201,409]);for(const r of races)await r.text();
 assert.equal((await db.prepare("SELECT COUNT(*) n FROM users WHERE email='race2@example.com'").first()).n,1);
 await mf.dispose();mf=new Miniflare(options);db=await mf.getD1Database('DB');
 a=await login('first@example.com');assert.deepEqual((await request('/api/preferences?key=goals',{cookie:a.cookie})).data.value,['Account A only']);
 await db.prepare('UPDATE auth_sessions SET created_at=? WHERE user_id=?').bind(Date.now()-31*86400000,a.data.user.id).run();
 await request('/api/me',{cookie:a.cookie,status:401});a=await login('first@example.com');
 const rows=await db.prepare('SELECT password_hash FROM user_credentials WHERE user_id=?').bind(a.data.user.id).first();assert.ok(rows.password_hash&&!rows.password_hash.includes(password));
 console.log('Email signup, duplicate race, separate accounts, protected demo OTP, logout/login and database restart passed.');
 const {createRequire}=await import('node:module');const {chromium}=createRequire(import.meta.url)('playwright');
 const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_EXECUTABLE||'/tmp/chromium',args:['--no-sandbox']});
 try{
 const context=await browser.newContext({viewport:{width:1280,height:900}});context.setDefaultTimeout(15000);const page=await context.newPage();const base=(await mf.ready).origin;const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(base+'/login');await page.getByRole('button',{name:'Create Student Account'}).click();
 await page.getByLabel('Email address',{exact:true}).fill('browser@example.com');await page.getByLabel('Password',{exact:true}).fill(password);await page.getByLabel('Confirm password',{exact:true}).fill(password);await page.getByRole('button',{name:'Continue',exact:true}).click();await page.getByLabel('Full name',{exact:true}).fill('Browser Student');await page.getByLabel('College registration number',{exact:true}).fill('BROWSER-2026');await page.getByRole('button',{name:'Create account',exact:true}).click();
 await page.getByRole('button',{name:'Home',exact:true}).waitFor();assert.ok((await page.locator('.phone-frame').boundingBox()).width<=421);assert.equal(await page.locator('aside').count(),0);await page.getByRole('button',{name:'Chats',exact:true}).waitFor();
 await page.screenshot({path:'/workspace/scratch/aec6b105e479/qa-phone-desktop.png'});
 await context.request.post(base+'/api/auth',{data:{action:'logout'}});await page.goto(base+'/login');await page.locator('input[type=email]').fill('browser@example.com');await page.getByLabel('Password',{exact:true}).fill(password);await page.getByRole('button',{name:'Sign in with password'}).click();await page.getByRole('button',{name:'Home',exact:true}).waitFor();
 await page.setViewportSize({width:390,height:844});assert.ok((await page.locator('.phone-frame').boundingBox()).width<=390);await page.getByRole('button',{name:'Campus',exact:true}).waitFor();assert.deepEqual(errors,[]);await page.screenshot({path:'/workspace/scratch/aec6b105e479/qa-email-signup-mobile.png'});
 console.log('Browser signup, logout, email login and identical phone navigation on desktop/mobile passed.');
 }finally{await browser.close();}
}finally{await mf.dispose();}
