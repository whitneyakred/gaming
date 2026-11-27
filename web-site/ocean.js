// A small, decorative ocean: fixed creature count, capped resolution, no work offscreen.
const hero=document.querySelector('.hero'), canvas=document.querySelector('#ocean-life');
const context=canvas.getContext('2d'), toggle=document.querySelector('.motion');
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
let paused=reduced.matches, visible=true, clock=0, previous=0, frame=0;
const shark=new Image();shark.src='/shark.png';
const offsets=[[-26,2],[-8,2],[10,2],[28,1],[-26,9],[-8,10],[9,10],[26,10],[-26,15],[-8,17],[9,16],[27,16]];
function resize(){canvas.width=Math.min(1440,hero.clientWidth);canvas.height=Math.round(canvas.width*hero.clientHeight/hero.clientWidth);context.imageSmoothingEnabled=false;draw();}
function draw(){
 const w=canvas.width,h=canvas.height;context.clearRect(0,0,w,h);
 // Small square surface glints drift independently of the ocean artwork.
 for(let i=0;i<35;i++){const x=(i*137+clock*3)%w,y=(i*79)%h;context.fillStyle=`rgba(147,208,221,${.08+.12*(1+Math.sin(clock+i))/2})`;context.fillRect(x,y,8+(i%3)*4,2);}
 if(!shark.complete||!shark.naturalWidth)return;
 const cw=shark.width/4,ch=shark.height/3;
 for(let i=0;i<3;i++){
  const angle=clock*(.055+i*.012)+i*2.1;
  const x=w*.72+Math.cos(angle)*w*.20,y=h*.5+Math.sin(angle)*h*.36;
  const direction=Math.atan2(Math.cos(angle)*h*.36,-Math.sin(angle)*w*.20)+Math.PI/2;
  const cell=Math.floor(clock*4.5+i*4)%12,s=w<650?.12:.20;
  context.save();context.translate(x,y);context.rotate(direction);context.globalAlpha=.7;
  const off=offsets[cell];context.drawImage(shark,cell%4*cw,Math.floor(cell/4)*ch,cw,ch,(-cw/2+off[0])*s,(-ch/2+off[1])*s,cw*s,ch*s);
  context.globalAlpha=.25;context.fillStyle='#d8eef0';for(let b=0;b<5;b++){const t=(clock*.7+b/5)%1;context.fillRect((b%2?1:-1)*(3+t*14),10+t*30,2,3);}context.restore();
 }
}
function tick(now){frame=0;if(paused||!visible||document.hidden)return;if(previous){clock+=Math.min((now-previous)/1000,.05);}previous=now;draw();frame=requestAnimationFrame(tick);}
function sync(){cancelAnimationFrame(frame);previous=0;hero.classList.toggle('still',paused);toggle.textContent=paused?'Animate ocean':'Pause ocean';toggle.setAttribute('aria-pressed',String(paused));draw();if(!paused&&visible&&!document.hidden)frame=requestAnimationFrame(tick);}
toggle.addEventListener('click',()=>{paused=!paused;sync();});reduced.addEventListener('change',()=>{paused=reduced.matches;sync();});
document.addEventListener('visibilitychange',sync);new IntersectionObserver(([entry])=>{visible=entry.isIntersecting;sync();}).observe(hero);new ResizeObserver(resize).observe(hero);shark.addEventListener('load',draw);resize();sync();
