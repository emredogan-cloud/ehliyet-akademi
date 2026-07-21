/**
 * QIP — Faz 3 · Bilgi Grafiği (BANK_QUESTİON Part 3).
 *
 * Tipli düğüm/kenar grafiği: Soru ↔ Ders ↔ Trafik İşareti ↔ Araç Parçası ↔ Konu ↔ Tema ↔ Ders(subject)
 * ↔ Senaryo. Kenarlar Faz 1 çapraz bağları + Faz 2 sınıflandırmasından türetilir (gerçek içerik).
 * Öneri motorunu (relatedQuestions/relatedContent) besler → "graph should support future
 * recommendations". Saf/deterministik; bir kez kurulur ve önbelleğe alınır.
 */
import { SUBJECT_LABEL } from '@ea/content-schema';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { LESSONS } from '@/content/lessons';
import { SCENARIOS } from '@/content/scenarios';
import { analyzedQuestions, type AnalyzedQuestion } from './index';
import { DRIVING_RULES } from './knowledge';

export type NodeType =
  'question' | 'lesson' | 'sign' | 'part' | 'topic' | 'theme' | 'subject' | 'scenario' | 'rule';

export type EdgeType =
  | 'belongs-to' // question/lesson/topic/theme/rule → subject
  | 'about-topic' // question → topic
  | 'classified-as' // question → theme
  | 'related-lesson' // question/sign/part/scenario → lesson
  | 'depicts-sign' // question → sign
  | 'depicts-part' // question → vehicle part
  | 'rule-topic'; // rule (law/fact) → topic

export interface GraphNode {
  id: string; // `${type}:${rawId}`
  type: NodeType;
  label: string;
  ref: string; // ham id (tür öneki olmadan)
}

export interface GraphEdge {
  from: string;
  to: string;
  type: EdgeType;
}

export interface Graph {
  nodes: Map<string, GraphNode>;
  adj: Map<string, GraphEdge[]>;
}

const nid = (type: NodeType, ref: string) => `${type}:${ref}`;
const trunc = (s: string, n = 80) => (s.length > n ? s.slice(0, n - 1) + '…' : s);

let _graph: Graph | null = null;

function addNode(g: Graph, type: NodeType, ref: string, label: string): string {
  const id = nid(type, ref);
  if (!g.nodes.has(id)) {
    g.nodes.set(id, { id, type, label, ref });
    g.adj.set(id, []);
  }
  return id;
}

function addEdge(g: Graph, from: string, to: string, type: EdgeType): void {
  if (!g.nodes.has(from) || !g.nodes.has(to)) return;
  g.adj.get(from)!.push({ from, to, type });
  g.adj.get(to)!.push({ from: to, to: from, type });
}

/** Grafiği kur (varsayılan girdi için bir kez, önbellekli). */
export function buildGraph(pool?: AnalyzedQuestion[]): Graph {
  const usingDefault = pool === undefined;
  if (_graph && usingDefault) return _graph;
  const data = pool ?? analyzedQuestions();
  const g: Graph = { nodes: new Map(), adj: new Map() };

  // Ders düğümleri
  for (const [key, label] of Object.entries(SUBJECT_LABEL)) addNode(g, 'subject', key, label);
  // Ders (lesson) düğümleri + ders→subject
  for (const l of LESSONS) {
    addNode(g, 'lesson', l.slug, l.title);
    addEdge(g, nid('lesson', l.slug), nid('subject', l.subject), 'belongs-to');
  }
  // İşaret düğümleri + işaret→ders
  for (const s of SIGNS) {
    addNode(g, 'sign', s.id, s.name);
    if (s.relatedLessonSlug)
      addEdge(g, nid('sign', s.id), nid('lesson', s.relatedLessonSlug), 'related-lesson');
  }
  // Araç parçası düğümleri + parça→ders
  for (const p of VEHICLE_PARTS) {
    addNode(g, 'part', p.id, p.name);
    if (p.relatedLessonSlug)
      addEdge(g, nid('part', p.id), nid('lesson', p.relatedLessonSlug), 'related-lesson');
  }
  // Senaryo düğümleri + senaryo→ders
  for (const sc of SCENARIOS) {
    addNode(g, 'scenario', sc.id, sc.title);
    if (sc.relatedLessonSlug)
      addEdge(g, nid('scenario', sc.id), nid('lesson', sc.relatedLessonSlug), 'related-lesson');
  }

  // Soru düğümleri + tüm kenarlar
  for (const q of data) {
    const qid = addNode(g, 'question', q.id, trunc(q.stem));
    // konu + tema düğümleri (tembel oluşturma)
    addNode(g, 'topic', q.topic, q.topic);
    addNode(g, 'theme', q.primaryTheme, q.primaryThemeLabel);
    addEdge(g, qid, nid('subject', q.subject), 'belongs-to');
    addEdge(g, qid, nid('topic', q.topic), 'about-topic');
    addEdge(g, qid, nid('theme', q.primaryTheme), 'classified-as');
    addEdge(g, nid('topic', q.topic), nid('subject', q.subject), 'belongs-to');
    addEdge(g, nid('theme', q.primaryTheme), nid('subject', q.subject), 'belongs-to');
    if (q.relatedLesson) addEdge(g, qid, nid('lesson', q.relatedLesson), 'related-lesson');
    for (const sgn of q.relatedSigns) addEdge(g, qid, nid('sign', sgn), 'depicts-sign');
    for (const prt of q.relatedVehicleParts) addEdge(g, qid, nid('part', prt), 'depicts-part');
  }

  // Kural (kanun/olgu) düğümleri — Faz 2 bilgi katmanı; paylaşılan konu düğümleriyle bağlanır
  // (özgün soru ↔ ortak konu ↔ ilgili kural). BANK_QUESTİON Part 3 "Law" vizyonu.
  for (const r of DRIVING_RULES) {
    const rid = addNode(g, 'rule', r.id, r.statement.slice(0, 80));
    addEdge(g, rid, nid('subject', r.subject), 'belongs-to');
    for (const t of r.topics) {
      addNode(g, 'topic', t, t);
      addEdge(g, rid, nid('topic', t), 'rule-topic');
      addEdge(g, nid('topic', t), nid('subject', r.subject), 'belongs-to');
    }
  }

  if (usingDefault) _graph = g;
  return g;
}

/** Bir düğümün komşuları (opsiyonel kenar/düğüm türü filtresi). */
export function neighbors(
  nodeId: string,
  opts: { edgeType?: EdgeType; nodeType?: NodeType } = {},
  g: Graph = buildGraph()
): GraphNode[] {
  const edges = g.adj.get(nodeId) ?? [];
  const out: GraphNode[] = [];
  const seen = new Set<string>();
  for (const e of edges) {
    if (opts.edgeType && e.type !== opts.edgeType) continue;
    const n = g.nodes.get(e.to);
    if (!n) continue;
    if (opts.nodeType && n.type !== opts.nodeType) continue;
    if (seen.has(n.id)) continue;
    seen.add(n.id);
    out.push(n);
  }
  return out;
}

export interface RelatedContent {
  lessons: GraphNode[];
  signs: GraphNode[];
  parts: GraphNode[];
  scenarios: GraphNode[];
  questions: GraphNode[];
}

/**
 * Grafik-güdümlü ilgili içerik (öneri). 1-hop: ilgili ders/işaret/parça; 2-hop: aynı ders/işaret/
 * temayı paylaşan kardeş sorular, paylaşılan-bağ sayısına göre sıralı.
 */
export function relatedContent(
  questionId: string,
  limit = 8,
  g: Graph = buildGraph()
): RelatedContent {
  const qid = nid('question', questionId);
  if (!g.nodes.has(qid)) return { lessons: [], signs: [], parts: [], scenarios: [], questions: [] };

  const lessons = neighbors(qid, { nodeType: 'lesson' }, g);
  const signs = neighbors(qid, { nodeType: 'sign' }, g);
  const parts = neighbors(qid, { nodeType: 'part' }, g);

  // 2-hop kardeş sorular: bağlı ders/işaret/parça/tema üzerinden.
  const bridge = [...lessons, ...signs, ...parts, ...neighbors(qid, { nodeType: 'theme' }, g)];
  const score = new Map<string, number>();
  for (const b of bridge) {
    for (const nb of neighbors(b.id, { nodeType: 'question' }, g)) {
      if (nb.id === qid) continue;
      score.set(nb.id, (score.get(nb.id) ?? 0) + 1);
    }
  }
  const questions = [...score.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([id]) => g.nodes.get(id)!)
    .filter(Boolean);

  // İlgili senaryolar: bağlı derslerin senaryoları.
  const scenarios: GraphNode[] = [];
  const seenSc = new Set<string>();
  for (const l of lessons) {
    for (const sc of neighbors(l.id, { nodeType: 'scenario' }, g)) {
      if (!seenSc.has(sc.id)) {
        seenSc.add(sc.id);
        scenarios.push(sc);
      }
    }
  }
  return { lessons, signs, parts, scenarios, questions };
}

/** Öneri: bir soruya en çok bağ paylaşan soru id'leri (ham id). */
export function relatedQuestions(questionId: string, limit = 6, g: Graph = buildGraph()): string[] {
  return relatedContent(questionId, limit, g).questions.map((n) => n.ref);
}

export interface GraphStats {
  nodeCount: number;
  edgeCount: number;
  byNodeType: Record<string, number>;
  byEdgeType: Record<string, number>;
  /** Yalnız subject/topic/theme'e bağlı (ders/işaret/parça bağı olmayan) soru sayısı. */
  orphanQuestions: number;
  avgQuestionDegree: number;
}

/** Grafik istatistikleri — pano + rapor + testler için GERÇEK sayılar. */
export function graphStats(g: Graph = buildGraph()): GraphStats {
  const byNodeType: Record<string, number> = {};
  const byEdgeType: Record<string, number> = {};
  let edgeCount = 0;
  for (const n of g.nodes.values()) byNodeType[n.type] = (byNodeType[n.type] ?? 0) + 1;
  for (const edges of g.adj.values()) {
    for (const e of edges) byEdgeType[e.type] = (byEdgeType[e.type] ?? 0) + 1;
    edgeCount += edges.length;
  }
  // her kenar iki yönde sayıldı
  edgeCount = Math.round(edgeCount / 2);
  for (const k of Object.keys(byEdgeType)) byEdgeType[k] = Math.round(byEdgeType[k]! / 2);

  let orphanQuestions = 0;
  let qDegreeSum = 0;
  let qCount = 0;
  for (const n of g.nodes.values()) {
    if (n.type !== 'question') continue;
    qCount++;
    const edges = g.adj.get(n.id) ?? [];
    qDegreeSum += edges.length;
    const hasRich = edges.some(
      (e) => e.type === 'related-lesson' || e.type === 'depicts-sign' || e.type === 'depicts-part'
    );
    if (!hasRich) orphanQuestions++;
  }
  return {
    nodeCount: g.nodes.size,
    edgeCount,
    byNodeType,
    byEdgeType,
    orphanQuestions,
    avgQuestionDegree: qCount ? Math.round((qDegreeSum / qCount) * 10) / 10 : 0,
  };
}
