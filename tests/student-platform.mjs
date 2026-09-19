import {Miniflare} from 'miniflare';
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
 const login=async n=>(await request('/api/auth',{method:'POST',body:{action:'demo-login',userId:'demo-user-'+n}})).cookie;
 const a=await login(0),b=await login(1),c=await login(2);
 const post=(path,cookie,body,status=200)=>request(path,{method:'POST',cookie,body,status});
 const expired=(await post('/api/chats',a,{action:'initiate',receiverId:'demo-user-1',message:'Please connect with me'},201)).data.sessionId;
 await db.prepare("UPDATE chat_sessions SET timer_ends_at=? WHERE id=?").bind(Date.now()-1,expired).run();
 await db.prepare("UPDATE users SET is_restricted=1 WHERE id='demo-user-0'").run();
 assert.equal((await request('/api/me',{cookie:a})).data.user.isRestricted,false);
 await post('/api/chats',a,{action:'initiate',receiverId:'demo-user-1',message:'Try again'},403);
 const other=(await post('/api/chats',a,{action:'initiate',receiverId:'demo-user-2',message:'Other people remain available'},201)).data.sessionId;assert.ok(other);
 await post('/api/chats',b,{action:'respond',sessionId:expired,response:'accept'});
 await post('/api/chats',a,{action:'message',sessionId:expired,kind:'text',body:'Reopened successfully'});
 console.log('48-hour expiry is conversation-only; other chats and recipient reopen pass.');
 const start=Date.now()+3600000,end=start+3600000;
 const lecture=(await post('/api/planner',a,{action:'create',kind:'lecture',title:'AI lecture',notes:'',startsAt:start,endsAt:end,remindAt:start-60000,room:'B34-201',shared:true},201)).data.id;
 await post('/api/planner',b,{action:'delete',id:lecture},404);
 const rooms=(await request(`/api/planner?view=rooms&start=${start-1800000}&end=${end+1800000}`,{cookie:b})).data.rooms;
 assert.equal(rooms.length,1);assert.deepEqual(rooms[0].free,[{start:start-1800000,end:start},{start:end,end:end+1800000}]);
 assert.equal((await request('/api/planner',{cookie:b})).data.items.length,0);
 const task=(await post('/api/planner',a,{action:'create',kind:'assignment',title:'Submit CA',startsAt:start,endsAt:end,remindAt:start-60000},201)).data.id;
 await post('/api/planner',a,{action:'done',id:task,done:true});
 const q=(await post('/api/forum',a,{action:'ask',title:'How do joins work?',body:'Explain an SQL join with an example.'},201)).data.id;
 await post('/api/forum',b,{action:'answer',questionId:q,body:'Join rows through matching keys.'},201);
 assert.equal((await request('/api/forum?id='+q,{cookie:a})).data.answers.length,1);
 await post('/api/forum',b,{action:'delete-question',id:q},404);
 console.log('Shared room gaps, private planner, assignment completion and forum answers pass.');
 const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aU1sAAAAASUVORK5CYII=','base64');
 async function upload(cookie,purpose,bytes=png,mime='image/png'){const form=new FormData();form.set('purpose',purpose);form.set('file',new File([bytes],'test.'+(purpose==='resume'?'pdf':'png'),{type:mime}));const serialized=new Request('http://localhost/api/student-files',{method:'POST',headers:{Cookie:cookie},body:form});const r=await mf.dispatchFetch(serialized.url,{method:'POST',headers:Object.fromEntries(serialized.headers),body:await serialized.arrayBuffer()});const d=await r.json();assert.equal(r.status,201,JSON.stringify(d));return d.id;}
 const photo=await upload(a,'profile'),resume=await upload(a,'resume',Buffer.from('%PDF-1.4\n%test\n%%EOF'),'application/pdf');
 await post('/api/student',a,{action:'save',name:'Updated Student',age:19,college:'LPU',registration:'REG-TEST-1',bio:'I build campus apps',availability:'internship',photoId:photo,resumeId:resume});
 await post('/api/student',b,{action:'save',name:'Other Student',age:19,college:'LPU',registration:'REG-TEST-1',bio:'',availability:'student'},409);
 assert.equal((await request('/api/me',{cookie:a})).data.user.fullName,'Updated Student');
 await request('/api/student-files/'+resume,{cookie:b,status:403});await post('/api/student',a,{action:'send-verification'},503);
 const parcel=(await post('/api/parcels',a,{action:'create',title:'Books parcel',pickup:'Main gate',destination:'BH1',dueAt:end,parcelAmount:10000,fee:2000},201)).data.id;
 const claim=await Promise.all([b,c].map(cookie=>mf.dispatchFetch('http://localhost/api/parcels',{method:'POST',headers:{Cookie:cookie,'Content-Type':'application/json'},body:JSON.stringify({action:'claim',id:parcel})})));assert.deepEqual(claim.map(r=>r.status).sort(),[200,409]);const courier=claim[0].status===200?b:c,outsider=claim[0].status===200?c:b;for(const r of claim)await r.text();
 await post('/api/parcels',courier,{action:'handover',id:parcel},409);
 const parcelPhoto=await upload(courier,'parcel'),qrPhoto=await upload(courier,'qr');await post('/api/parcels',courier,{action:'ready',id:parcel,parcelPhoto,qrPhoto});
 await request('/api/student-files/'+qrPhoto,{cookie:outsider,status:403});
 const receiptPhoto=await upload(a,'receipt');await post('/api/parcels',a,{action:'receipt',id:parcel,receiptPhoto});await post('/api/parcels',a,{action:'confirm-payment',id:parcel,confirm:true},409);
 await post('/api/parcels',courier,{action:'confirm-payment',id:parcel,confirm:true});await post('/api/parcels',courier,{action:'handover',id:parcel});await post('/api/parcels',a,{action:'received',id:parcel});
 await post('/api/parcels',a,{action:'complaint',id:parcel,category:'damaged',body:'The outside box is damaged.'},201);
 assert.equal((await request('/api/parcels',{cookie:a})).data.complaints.length,1);
 console.log('Profile, registration uniqueness, private PDF, parcel claim race, payment gate and complaint evidence pass.');
 await mf.dispose();mf=new Miniflare(options);db=await mf.getD1Database('DB');
 assert.equal((await request('/api/parcels',{cookie:a})).data.parcels.find(p=>p.id===parcel).status,'delivered');assert.equal((await request('/api/student',{cookie:a})).data.profile.resume_id,resume);assert.ok((await request('/api/planner',{cookie:a})).data.items.find(i=>i.id===task).done);
 console.log('New records survive Worker restart.');
 const {createHmac}=await import('node:crypto');const otpHash=createHmac('sha256',options.bindings.OTP_SIGNING_SECRET).update('demo-user-0:123456').digest('hex');
 await db.prepare('INSERT INTO verification_challenges(user_id,code_hash,expires_at,attempts,created_at) VALUES(?,?,?,0,?)').bind('demo-user-0',otpHash,Date.now()+600000,Date.now()).run();
 await post('/api/student',a,{action:'verify-email',code:'000000'},422);await post('/api/student',a,{action:'verify-email',code:'123456'});await post('/api/student',a,{action:'verify-email',code:'123456'},422);
 const signup=await request('/api/auth',{method:'POST',status:201,body:{action:'signup',email:'delete-me@example.com',password:'DeleteAccount!2026',collegeRegistration:'DELETE-TEST',fullName:'Deletion Test',course:'BCA',academicYear:1,gender:'prefer_not_to_say'}});
 const doomedFile=await upload(signup.cookie,'profile');const doomedKey=(await db.prepare('SELECT object_key FROM student_files WHERE id=?').bind(doomedFile).first()).object_key;
 await post('/api/student',signup.cookie,{action:'delete-account',confirm:'DELETE',password:'wrong'},401);
 await post('/api/student',signup.cookie,{action:'delete-account',confirm:'DELETE',password:'DeleteAccount!2026'});
 await request('/api/me',{cookie:signup.cookie,status:401});assert.equal(await db.prepare('SELECT id FROM users WHERE id=?').bind(signup.data.user.id).first(),null);assert.equal(await (await mf.getR2Bucket('BUCKET')).get(doomedKey),null);
 console.log('Email OTP validation/replay protection and password-confirmed account/file deletion pass.');

 const {createRequire}=await import('node:module');const require=createRequire(import.meta.url);const {chromium}=require('playwright');const ts=require('typescript');const {writeFileSync,unlinkSync}=await import('node:fs');
 const harness=resolve('dist/client/crypto-test.js');writeFileSync(harness,ts.transpileModule(readFileSync('src/lib/chat-crypto.ts','utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ES2022}}).outputText);
 const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_EXECUTABLE||undefined,args:['--no-sandbox']});
 try{
 const base=(await mf.ready).origin;const contexts=await Promise.all([a,b].map(async cookie=>{const ctx=await browser.newContext({viewport:{width:390,height:844}});await ctx.route('**/crypto-test.js',route=>route.fulfill({contentType:'text/javascript',body:readFileSync(harness,'utf8')}));await ctx.addCookies([{name:'quad_session',value:cookie.split('=')[1],url:base}]);return ctx;}));const pages=await Promise.all(contexts.map(c=>c.newPage()));
 for(const p of pages){await p.goto(base+'/privacy');await p.evaluate(async()=>{window.cryptoTest=await import('/crypto-test.js');await window.cryptoTest.ensureChatIdentity();});}
 const secret='Only the two students should read this.';
 const cipher=await pages[0].evaluate(async s=>window.cryptoTest.encryptChat(s,'text','userId=demo-user-1'),secret);assert.ok(!cipher.includes(secret));
 await post('/api/chats',a,{action:'message',sessionId:expired,kind:'text',body:cipher});assert.equal((await db.prepare('SELECT body FROM messages WHERE body=?').bind(cipher).first()).body,cipher);
 const plain=await pages[1].evaluate(async cipher=>window.cryptoTest.decryptChat(cipher),cipher);assert.equal(plain.body,secret);
 const imageBody='data:image/png;base64,'+png.toString('base64');const imageCipher=await pages[0].evaluate(body=>window.cryptoTest.encryptChat(body,'image','userId=demo-user-1'),imageBody);await post('/api/chats',a,{action:'message',sessionId:expired,kind:'image',body:imageCipher});
 const imageRow=await db.prepare("SELECT body FROM messages WHERE session_id=? AND kind='image' ORDER BY created_at DESC LIMIT 1").bind(expired).first();assert.ok(imageRow.body.startsWith('e2ee-media:'));assert.equal((await pages[1].evaluate(body=>window.cryptoTest.decryptChat(body),imageRow.body)).body,imageBody);
 await assert.rejects(()=>pages[1].evaluate(cipher=>{const e=JSON.parse(cipher.slice(8));e.cipher=(e.cipher[0]==='A'?'B':'A')+e.cipher.slice(1);return window.cryptoTest.decryptChat('e2ee:v1:'+JSON.stringify(e));},cipher));
 const backup=await pages[0].evaluate(()=>window.cryptoTest.exportChatBackup('LongBackup!Password2026'));assert.ok(!backup.includes('privateKey'));
 await assert.rejects(()=>pages[0].evaluate(backup=>window.cryptoTest.importChatBackup(backup,'WrongBackupPassword2026'),backup));
 const restored=await browser.newContext();await restored.route('**/crypto-test.js',route=>route.fulfill({contentType:'text/javascript',body:readFileSync(harness,'utf8')}));await restored.addCookies([{name:'quad_session',value:a.split('=')[1],url:base}]);const restorePage=await restored.newPage();await restorePage.goto(base+'/privacy');await restorePage.evaluate(async backup=>{const c=await import('/crypto-test.js');await c.importChatBackup(backup,'LongBackup!Password2026');window.cryptoTest=c;},backup);assert.equal((await restorePage.evaluate(cipher=>window.cryptoTest.decryptChat(cipher),cipher)).body,secret);
 const p=pages[0];await p.goto(base);await p.getByRole('button',{name:'Essential only',exact:true}).click();await p.getByRole('button',{name:'Plan your day · Campus desk',exact:true}).click();await p.getByRole('button',{name:'Forum',exact:true}).click();await p.getByRole('button',{name:'How do joins work?',exact:true}).waitFor();await p.getByRole('button',{name:'Close campus desk',exact:true}).click();await p.getByTitle('Open profile',{exact:true}).click();await p.getByText('Your campus profile',{exact:true}).waitFor();assert.equal(await p.getByText(/Verified Student Standing|officially verified|Institutional ID Verified|new chat requests paused/).count(),0);await p.getByRole('button',{name:'Home',exact:true}).click();await p.getByRole('button',{name:'Buddies',exact:true}).click();
 await p.getByText(/students found/).waitFor();const header=p.getByText('Campus Community',{exact:true});const before=(await header.boundingBox()).y;await p.getByText(/students found/).evaluate(el=>{let n=el.parentElement;while(n&&n.scrollHeight<=n.clientHeight)n=n.parentElement;if(n)n.scrollTop=250;});assert.ok((await header.boundingBox()).y<before,'Buddies header must scroll with content');
 const overflow=await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth);assert.equal(overflow,false);await p.screenshot({path:'/workspace/scratch/aec6b105e479/uni-update-mobile.png'});await p.setViewportSize({width:1280,height:900});assert.ok((await p.locator('.phone-frame').boundingBox()).width<=421);
 for(const path of ['/privacy','/terms','/robots.txt','/sitemap.xml','/favicon.svg']){const r=await contexts[0].request.get(base+path);assert.equal(r.status(),200,path);}
 const missing=await contexts[0].request.get(base+'/this-page-does-not-exist');assert.equal(missing.status(),404);const timings=await p.evaluate(()=>{const n=performance.getEntriesByType('navigation')[0];return {domContentLoadedMs:Math.round(n.domContentLoadedEventEnd),loadMs:Math.round(n.loadEventEnd)};});console.log('Local browser navigation timings (not production performance):',timings);
 console.log('Browser: cross-account encryption, encrypted backup restore, campus desk, mobile/desktop phone layout and public routes pass.');
 }finally{await browser.close();unlinkSync(harness);}
 console.log('ALL STUDENT PLATFORM TESTS PASSED');
}finally{await mf.dispose();}
