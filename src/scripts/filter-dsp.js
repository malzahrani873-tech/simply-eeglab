// Signal maths for the filter simulation: windowed-sinc FIR (Hamming), zero-phase via FFT,
// transition band and order chosen the way EEGLAB's pop_eegfiltnew does by default.
export const FS=250,NS=30000,NF=65536;
export function fft(re,im,inv){
  const n=re.length;
  for(let i=1,j=0;i<n;i++){let b=n>>1;for(;j&b;b>>=1)j^=b;j^=b;if(i<j){let t=re[i];re[i]=re[j];re[j]=t;t=im[i];im[i]=im[j];im[j]=t;}}
  for(let len=2;len<=n;len<<=1){const a=(inv?2:-2)*Math.PI/len,wr=Math.cos(a),wi=Math.sin(a);
    for(let i=0;i<n;i+=len){let cr=1,ci=0;for(let k=0;k<len/2;k++){const u=i+k,v=u+len/2;
      const xr=re[v]*cr-im[v]*ci,xi=re[v]*ci+im[v]*cr;re[v]=re[u]-xr;im[v]=im[u]-xi;re[u]+=xr;im[u]+=xi;
      const t=cr*wr-ci*wi;ci=cr*wi+ci*wr;cr=t;}}}
  if(inv){for(let i=0;i<n;i++){re[i]/=n;im[i]/=n;}}
}
const evenUp=x=>Math.ceil(x/2-1e-9)*2;
export function design(type,e){
  let df=type==='hp'?Math.min(Math.max(e*0.25,2),e):Math.min(Math.max(e*0.25,2),FS/2-e);
  const order=evenUp(3.3/(df/FS));df=3.3*FS/order;
  return {type,e,df,order,cut:type==='hp'?e-df/2:e+df/2};
}
const kcache={};
export function kernelFFT(spec){
  const key=spec.type+spec.e;if(kcache[key])return kcache[key];
  const M=spec.order,wc=spec.cut/FS,h=new Float64Array(M+1);let sum=0;
  for(let n=0;n<=M;n++){const k=n-M/2;const s=k===0?2*wc:Math.sin(2*Math.PI*wc*k)/(Math.PI*k);h[n]=s*(0.54-0.46*Math.cos(2*Math.PI*n/M));sum+=h[n];}
  for(let n=0;n<=M;n++)h[n]/=sum;
  if(spec.type==='hp'){for(let n=0;n<=M;n++)h[n]=-h[n];h[M/2]+=1;}
  const re=new Float64Array(NF),im=new Float64Array(NF);re.set(h);fft(re,im,false);
  return kcache[key]={re,im,delay:M/2};
}
export function applyFilters(X,specs){
  const re=Float64Array.from(X.re),im=Float64Array.from(X.im);let delay=0;
  for(const s of specs){const K=kernelFFT(s);delay+=K.delay;
    for(let i=0;i<NF;i++){const a=re[i],b=im[i];re[i]=a*K.re[i]-b*K.im[i];im[i]=a*K.im[i]+b*K.re[i];}}
  fft(re,im,true);return {y:re,delay};
}
function gauss(){let u=0,v=0;while(!u)u=Math.random();while(!v)v=Math.random();return Math.sqrt(-2*Math.log(u))*Math.cos(2*Math.PI*v);}
export function makeSignal(line){
  const x=new Float64Array(NS),dt=1/FS;
  const pr=new Float64Array(32768),pi=new Float64Array(32768);
  for(let k=1;k<16384;k++){const f=k*FS/32768;const a=1/Math.sqrt(Math.max(f,0.5));pr[k]=a*gauss();pi[k]=a*gauss();pr[32768-k]=pr[k];pi[32768-k]=-pi[k];}
  fft(pr,pi,true);let sd=0;for(let i=0;i<NS;i++)sd+=pr[i]*pr[i];sd=Math.sqrt(sd/NS);
  const aA=15+Math.random()*10,ph=[...Array(8)].map(()=>Math.random()*6.283);
  const drifts=[...Array(3)].map(()=>[0.02+Math.random()*0.13,(50+Math.random()*100)/2.2,Math.random()*6.283]);
  const bursts=[...Array(14)].map(()=>[Math.random()*NS*dt,0.15+Math.random()*0.35,6+Math.random()*8]);
  const mf=[...Array(10)].map(()=>[20+Math.random()*80,Math.random()*6.283]);
  for(let i=0;i<NS;i++){const t=i*dt;
    let v=pr[i]/sd*6;
    v+=aA*(0.65+0.35*Math.sin(2*Math.PI*0.15*t+ph[0]))*Math.sin(2*Math.PI*10*t+ph[1]);
    v+=7*Math.sin(2*Math.PI*6*t+ph[2])*(0.6+0.4*Math.sin(2*Math.PI*0.07*t+ph[3]));
    for(const [f,a,p] of drifts)v+=a*Math.sin(2*Math.PI*f*t+p);
    let env=0;for(const [c,w,a] of bursts){const z=(t-c)/w;if(Math.abs(z)<3)env+=a*Math.exp(-z*z*2);}
    if(env>0){let m=0;for(const [f,p] of mf)m+=Math.sin(2*Math.PI*f*t+p);v+=env*m*0.45;}
    v+=9*Math.sin(2*Math.PI*line*t);
    x[i]=v;}
  const re=new Float64Array(NF),im=new Float64Array(NF);re.set(x);fft(re,im,false);
  return {x,X:{re,im}};
}
export function welch(x,i0,i1){
  const L=1000,NFw=1024,step=500,P=new Float64Array(NFw/2+1);let cnt=0;
  const w=new Float64Array(L);for(let i=0;i<L;i++)w[i]=0.5-0.5*Math.cos(2*Math.PI*i/(L-1));
  for(let s=i0;s+L<=i1;s+=step){const re=new Float64Array(NFw),im=new Float64Array(NFw);
    let mu=0;for(let i=0;i<L;i++)mu+=x[s+i];mu/=L;
    for(let i=0;i<L;i++)re[i]=(x[s+i]-mu)*w[i];fft(re,im,false);
    for(let k=0;k<=NFw/2;k++)P[k]+=re[k]*re[k]+im[k]*im[k];cnt++;}
  for(let k=0;k<P.length;k++)P[k]/=cnt;return P;
}
export const fmt=(v,d)=>{const s=v.toFixed(d);return s.replace(/\.?0+$/,'')||'0';};
