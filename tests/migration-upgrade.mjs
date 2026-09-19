import {Miniflare} from 'miniflare';
import {readFileSync,readdirSync} from 'node:fs';
import assert from 'node:assert/strict';
const mf=new Miniflare({modules:true,script:'export default {fetch(){return new Response("migration test");}}',d1Databases:['DB'],r2Buckets:['BUCKET'],cf:false});
try{
 const db=await mf.getD1Database('DB');
 const apply=async file=>db.batch(readFileSync('drizzle/'+file,'utf8').split('--> statement-breakpoint').map(s=>s.trim()).filter(Boolean).map(s=>db.prepare(s)));
 const files=readdirSync('drizzle').filter(f=>f.endsWith('.sql')).sort();
 for(const file of files.filter(f=>Number(f.slice(0,4))<6))await apply(file);
 const now=Date.now();
 await db.prepare('INSERT INTO users(id,full_name,reg_id,email,mobile,gender,course,academic_year,created_at) VALUES(?,?,?,?,?,?,?,?,?)').bind('existing-account','Existing Test Student','EXISTING-1','existing@example.com','email:existing@example.com','prefer_not_to_say','BCA',1,now).run();
 await db.batch([
 db.prepare('INSERT INTO user_credentials(user_id,password_hash,updated_at) VALUES(?,?,?)').bind('existing-account','existing-hash-must-not-change',now),
 db.prepare('INSERT INTO auth_sessions(id,token,user_id,created_at) VALUES(?,?,?,?)').bind('existing-session','existing-token','existing-account',now),
 db.prepare('INSERT INTO login_attempts(identifier,attempts,window_start) VALUES(?,?,?)').bind('existing@example.com',5,now),
 db.prepare('INSERT INTO events(id,title,location,starts_at) VALUES(?,?,?,?)').bind('existing-event','Existing event','Campus',now),
 db.prepare('INSERT INTO vendors(id,name) VALUES(?,?)').bind('existing-vendor','Existing cafe'),
 db.prepare('INSERT INTO community_records(id,kind,owner_id,data,sample,created_at,updated_at) VALUES(?,?,?,?,?,?,?)').bind('existing-record','campus_pin','existing-account','{"title":"Existing content"}',1,now,now),
 db.prepare('INSERT INTO career_catalog(id,kind,data,sample,created_at) VALUES(?,?,?,?,?)').bind('existing-career','opportunity','{"title":"Existing role"}',1,now)
 ]);
 const bucket=await mf.getR2Bucket('BUCKET');await bucket.put('existing-upload','existing-file-bytes');
 const oldTables=(await db.prepare("SELECT name,sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name").all()).results;
 const snapshot=new Map();for(const t of oldTables)snapshot.set(t.name,(await db.prepare('SELECT * FROM "'+t.name+'" ORDER BY rowid').all()).results);
 for(const file of files.filter(f=>Number(f.slice(0,4))>=6)){
  const sql=readFileSync('drizzle/'+file,'utf8');assert.ok(sql.split('--> statement-breakpoint').map(s=>s.trim()).filter(Boolean).every(s=>/^CREATE (TABLE|(?:UNIQUE )?INDEX)\b/i.test(s)),file+' must remain additive');await apply(file);
 }
 for(const table of oldTables){assert.deepEqual((await db.prepare('SELECT * FROM "'+table.name+'" ORDER BY rowid').all()).results,snapshot.get(table.name),table.name+' rows changed');assert.equal((await db.prepare('SELECT sql FROM sqlite_master WHERE name=?').bind(table.name).first()).sql,table.sql,table.name+' schema changed');}
 assert.equal(await (await bucket.get('existing-upload')).text(),'existing-file-bytes');
 assert.equal((await db.prepare('PRAGMA foreign_key_check').all()).results.length,0);
 for(const table of ['student_profiles','student_files','planner_items','forum_questions','forum_answers','facility_complaints','parcels','parcel_complaints','verification_challenges','analytics_daily','chat_identity_keys'])assert.equal((await db.prepare('SELECT count(*) AS n FROM '+table).first()).n,0);
 console.log('UPGRADE PASSED: 0000–0005 existing schemas/rows, account hash, session, seeded records and R2 file unchanged after 0006/0007; 11 new empty tables; foreign keys valid.');
}finally{await mf.dispose();}
