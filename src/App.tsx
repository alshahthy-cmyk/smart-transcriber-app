/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { 
  Mic2, 
  Video, 
  FileAudio, 
  Settings, 
  Play, 
  XSquare, 
  CheckCircle2, 
  Clock, 
  History,
  AlertCircle,
  Smartphone,
  Key,
  Save,
  Wifi,
  X,
  Copy,
  Share2,
  FileText,
  Search
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

export default function App() {
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);

  const [isExtracting, setIsExtracting] = useState(false);
  const [isSplitting, setIsSplitting] = useState(false);
  const [isEnhancing, setIsEnhancing] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [chunks, setChunks] = useState<{ id: number, text: string, status: string, progress: number }[]>([]);

  // Results State
  const [showResults, setShowResults] = useState(false);
  const [finalText, setFinalText] = useState("");
  const [searchQuery, setSearchQuery] = useState("");

  // Settings State
  const [showSettings, setShowSettings] = useState(false);
  const [apiKey, setApiKey] = useState('');
  const [isTestingApiKey, setIsTestingApiKey] = useState(false);
  const [apikeyTestResult, setApiKeyTestResult] = useState<{success: boolean, msg: string} | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('mock_groq_key');
    if (saved) setApiKey(saved);
  }, []);

  const handleTestKey = () => {
    if (!apiKey) {
       setApiKeyTestResult({ success: false, msg: 'الرجاء إدخال المفتاح أولاً' });
       return;
    }
    setIsTestingApiKey(true);
    setApiKeyTestResult(null);
    setTimeout(() => {
      setIsTestingApiKey(false);
      // Mock validation
      if (apiKey.startsWith('gsk_') && apiKey.length > 20) {
        setApiKeyTestResult({ success: true, msg: 'تم الاتصال بنجاح! المفتاح صالح.' });
      } else {
        setApiKeyTestResult({ success: false, msg: 'مفتاح API غير صالح (يجب أن يبدأ بـ gsk_)' });
      }
    }, 1500);
  };

  const saveSettings = () => {
    localStorage.setItem('mock_groq_key', apiKey);
    setShowSettings(false);
  };

  // Mock function to simulate a file pick and progress inside the web preview
  const handleSimulateAction = (type: 'audio' | 'video') => {
    setProgress(0);
    setIsProcessing(false);
    setChunks([]);
    
    const isVideo = type === 'video';
    setSelectedFile(`test_${type}_arabic_sample.${isVideo ? 'mp4' : 'mp3'}`);
    setIsExtracting(true); // Simulate FFmpeg processing
    let extractProg = 0;
    const interval = setInterval(() => {
      extractProg += Math.random() * 15 + 5;
      if (extractProg >= 100) {
        extractProg = 100;
        clearInterval(interval);
        setTimeout(() => {
          setIsExtracting(false);
          setSelectedFile(`processed_audio_16kHz_mono.wav`);
          setProgress(0);
          
          // Phase A5: Mock Split
          setIsSplitting(true);
          setTimeout(() => {
            setIsSplitting(false);
            setChunks([
              { id: 1, text: 'الجزء الأول', status: 'pending', progress: 0 },
              { id: 2, text: 'الجزء الثاني', status: 'pending', progress: 0 }
            ]);
          }, 800);
        }, 500);
      }
      setProgress(Math.min(extractProg, 100));
    }, 300);
  };

  const handleStartSimulatedProcessing = () => {
    if (!selectedFile) return;
    setIsProcessing(true);
    setIsPaused(false);
    let currentProgress = progress;
    
    setChunks(c => c.map(ch => ({ ...ch, status: 'uploading' })));

    let mockCancel = false;

    // Simulate progress
    const interval = setInterval(() => {
      if (mockCancel || (window as any)._isPaused) return;

      currentProgress += Math.random() * 5 + 2;
      
      setChunks(c => c.map((ch, idx) => ({ 
        ...ch, 
        progress: idx === 0 ? Math.min(currentProgress * 1.5, 100) : currentProgress 
      })));

      if (currentProgress >= 100) {
        currentProgress = 100;
        clearInterval(interval);
        
        setChunks(c => c.map((ch) => ({ ...ch, status: 'completed', progress: 100 })));

        setTimeout(() => {
          setIsProcessing(false);
          setIsEnhancing(true);

          setTimeout(() => {
            setIsEnhancing(false);
            setProgress(0);
            setIsPaused(false);
            (window as any)._isPaused = false;
            setFinalText("هذا نص تجريبي لتفريغ الصوت العربي. في هذا التطبيق، نهتم برفع دقة التفريغ، إزالة التكرار، ودعم اللهجات العربية المختلفة بشكل احترافي. يمكنك البحث، النسخ، والمشاركة! \n\nقمنا بدمج أفضل التقنيات لمساعدتك على استخراج النصوص من الفيديوهات والصوتيات بأعلى كفاءة ممكنة.");
            setShowResults(true);
          }, 800);

        }, 1000);
      }
      setProgress(Math.min(currentProgress, 100));
    }, 500);

    (window as any)._cancelInterval = () => {
       mockCancel = true;
       clearInterval(interval);
       setIsProcessing(false);
       setProgress(0);
       setIsPaused(false);
       setChunks([]);
       (window as any)._isPaused = false;
    };
  };

  const togglePause = () => {
    if (isProcessing) {
       (window as any)._isPaused = !(window as any)._isPaused;
       setIsPaused((window as any)._isPaused);
    }
  };

  const cancelProcess = () => {
    if ((window as any)._cancelInterval) {
        (window as any)._cancelInterval();
    }
    setIsExtracting(false);
    setIsSplitting(false);
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4 font-sans text-gray-800">
      {/* Android Device Mockup Container */}
      <div className="w-full max-w-md bg-white rounded-[2.5rem] shadow-2xl overflow-hidden relative border-8 border-gray-900 h-[850px] max-h-[90vh] flex flex-col">
        
        {/* Status Bar Simulation */}
        <div className="bg-blue-600 text-white px-6 py-2 flex justify-between items-center text-xs font-medium">
          <span>{new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' })}</span>
          <div className="flex items-center gap-2">
            <Wifi size={14} />
            <Smartphone size={14} />
          </div>
        </div>

        {/* App Bar Material 3 */}
        <div className="bg-blue-600 text-white px-4 py-4 flex items-center justify-between shadow-md z-10 relative">
          <div className="flex items-center gap-3">
            <div className="bg-white/20 p-2 rounded-full">
              <Mic2 size={24} className="text-white" />
            </div>
            <h1 className="text-xl font-bold tracking-wide">تفريغ الصوت الذكي</h1>
          </div>
          <button 
            className="p-2 rounded-full hover:bg-white/10 transition-colors"
            onClick={() => setShowSettings(true)}
          >
            <Settings size={22} />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto bg-slate-50 p-5 space-y-6">
          
          {/* Welcome & Info */}
          <div className="bg-blue-50/50 rounded-2xl p-4 border border-blue-100 flex items-start gap-4">
            <AlertCircle className="text-blue-500 shrink-0 mt-1" size={24} />
            <div>
              <h2 className="text-blue-900 font-bold mb-1">وضع المعاينة (Preview Mode)</h2>
              <p className="text-sm text-blue-700 leading-relaxed">
                هذه نسخة محاكاة للواجهة (Mock UI) صممت لتعمل داخل AI Studio. 
                الميزات الأصلية (FFmpeg, File Picker) معطلة هنا لحين بناء الـ APK.
              </p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-4">
            <button 
              onClick={() => handleSimulateAction('audio')}
              className="bg-white border hover:border-blue-300 hover:bg-blue-50 border-gray-200 rounded-2xl p-6 flex flex-col items-center justify-center gap-3 shadow-sm transition-all active:scale-95"
            >
              <div className="bg-blue-100 p-4 rounded-full text-blue-600">
                <FileAudio size={28} />
              </div>
              <span className="font-semibold text-gray-700">ملف صوتي</span>
            </button>
            
            <button 
              onClick={() => handleSimulateAction('video')}
              className="bg-white border hover:border-blue-300 hover:bg-blue-50 border-gray-200 rounded-2xl p-6 flex flex-col items-center justify-center gap-3 shadow-sm transition-all active:scale-95"
            >
              <div className="bg-purple-100 p-4 rounded-full text-purple-600">
                <Video size={28} />
              </div>
              <span className="font-semibold text-gray-700">ملف فيديو</span>
            </button>
          </div>

          {/* File Information Card */}
          <AnimatePresence>
            {selectedFile && (
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden"
              >
                <div className="p-4 border-b border-gray-100 bg-gray-50 flex justify-between items-center">
                  <h3 className="font-bold text-gray-800">معلومات الملف</h3>
                  <CheckCircle2 size={18} className="text-green-500" />
                </div>
                <div className="p-4 space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500">اسم الملف:</span>
                    <span className="font-medium truncate max-w-[150px] text-left" dir="ltr">{selectedFile}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">المدة والنوع:</span>
                    <span className="font-medium">12:45 • MP4</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">الحجم المقدر:</span>
                    <span className="font-medium">18.5 MB</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">حالة الخادم:</span>
                    <span className="text-green-600 font-medium font-mono text-xs bg-green-50 px-2 py-1 rounded">Mock_Groq_Ready</span>
                  </div>
                </div>

                {/* Progress Indicators */}
                {(isProcessing || isExtracting || isSplitting || isEnhancing) && (
                  <div className="px-4 pb-4">
                    <div className="flex justify-between text-xs mb-1 font-medium">
                      <span className={isEnhancing ? "text-indigo-600" : (isExtracting ? "text-purple-600" : (isSplitting ? "text-orange-600" : "text-blue-600"))}>
                        {isEnhancing ? 'جاري تحسين وتنسيق النص العربي...' : (isExtracting ? 'معالجة وتحسين الصوت (FFmpeg)...' : (isSplitting ? 'تقسيم الملف الطويل (A5)...' : 'جاري الرفع والمعالجة...'))}
                      </span>
                      <span>{isEnhancing ? '100' : Math.round(progress)}%</span>
                    </div>
                    <div className="w-full bg-gray-100 rounded-full h-2 mb-2 overflow-hidden">
                      <motion.div 
                        className={`${isEnhancing ? "bg-indigo-600" : (isExtracting ? "bg-purple-600" : (isSplitting ? "bg-orange-600" : "bg-blue-600"))} h-2 rounded-full`}
                        style={{ width: isEnhancing ? '100%' : `${progress}%` }}
                        layout
                      />
                    </div>
                    {(!isExtracting && !isSplitting && !isEnhancing) && (
                      <div className="flex justify-between text-xs text-gray-500">
                        <span>السرعة: 1.2 MB/s</span>
                        <span>المتبقي: 00:15</span>
                      </div>
                    )}
                  </div>
                )}
                
                {chunks.length > 0 && (
                  <div className="px-4 pb-4">
                     <h4 className="text-xs font-bold text-gray-400 mb-2">الأجزاء المقسمة (A5)</h4>
                     <div className="space-y-2">
                       {chunks.map((ch) => (
                         <div key={ch.id} className="text-xs bg-gray-50 border border-gray-100 rounded p-2">
                            <div className="flex justify-between mb-1">
                               <span className="font-medium text-gray-600">{ch.text}</span>
                               <span className={ch.status === 'completed' ? 'text-green-600' : 'text-blue-500'}>
                                 {ch.status === 'completed' ? 'مكتمل' : (ch.status === 'uploading' ? 'جاري الرفع...' : 'في الانتظار')}
                               </span>
                            </div>
                            <div className="w-full bg-gray-200 rounded-full h-1 overflow-hidden">
                               <motion.div 
                                 className={`${ch.status === 'completed' ? "bg-green-500" : "bg-blue-500"} h-1 rounded-full`}
                                 style={{ width: `${ch.progress}%` }}
                                 layout
                               />
                            </div>
                         </div>
                       ))}
                     </div>
                  </div>
                )}
                
                {/* Action Controls */}
                <div className="p-4 bg-gray-50 flex gap-3">
                  {(!isProcessing && !isExtracting && !isSplitting && !isEnhancing) ? (
                    <button 
                      onClick={handleStartSimulatedProcessing}
                      className="flex-1 bg-blue-600 text-white rounded-xl py-3 px-4 font-bold flex items-center justify-center gap-2 hover:bg-blue-700 active:scale-95 transition-all shadow-md shadow-blue-200"
                    >
                      <Play size={18} />
                      البدء بالتفريغ
                    </button>
                  ) : (
                    <>
                      {(!isExtracting && !isSplitting && !isEnhancing) && (
                        <button 
                          onClick={togglePause}
                          className="flex-1 bg-white border border-gray-300 text-gray-700 rounded-xl py-3 px-4 font-bold flex items-center justify-center gap-2 hover:bg-gray-50 active:scale-95 transition-all"
                        >
                          <Play size={18} className={isPaused ? "fill-current" : ""} />
                          {isPaused ? 'استئناف' : 'إيقاف مؤقت'}
                        </button>
                      )}
                      <button 
                        onClick={cancelProcess}
                        disabled={isExtracting || isSplitting || isEnhancing}
                        className={`flex-1 ${isExtracting || isSplitting || isEnhancing ? 'bg-gray-100 text-gray-400 border-transparent' : 'bg-red-50 text-red-600 border border-red-200 hover:bg-red-100'} rounded-xl py-3 px-4 font-bold flex items-center justify-center gap-2 active:scale-95 transition-all`}
                      >
                        <XSquare size={18} />
                        إلغاء العملية
                      </button>
                    </>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* History Section */}
          <div className="mt-8">
            <h3 className="font-bold flex items-center gap-2 text-gray-700 mb-4 px-1">
              <History size={18} />
              العمليات السابقة
            </h3>
            
            <div className="space-y-3">
              {[1, 2].map((item) => (
                <div key={item} className="bg-white rounded-xl border border-gray-100 p-4 flex items-center gap-4 shadow-sm">
                  <div className="bg-green-100 p-3 rounded-full text-green-600">
                    <CheckCircle2 size={20} />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-semibold text-sm">اجتماع_الشركة_{item}.mp3</h4>
                    <div className="flex items-center gap-2 text-xs text-gray-500 mt-1">
                      <Clock size={12} />
                      <span>منذ {item * 2} ساعات</span>
                      <span>•</span>
                      <span>تم بنجاح (100%)</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>
        
        {/* Android Bottom Navigation Bar Simulation */}
        <div className="bg-white border-t border-gray-200 py-3 px-6 flex justify-around items-center">
          <div className="w-12 h-1 rounded-full bg-gray-900 mx-auto opacity-20"></div>
        </div>

        {/* Settings Overlay */}
        <AnimatePresence>
          {showSettings && (
            <motion.div 
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="absolute inset-0 z-50 bg-white flex flex-col"
            >
              <div className="bg-blue-600 text-white px-4 py-4 flex items-center shadow-md">
                <button 
                  className="p-2 rounded-full hover:bg-white/10 transition-colors"
                  onClick={() => setShowSettings(false)}
                >
                  <X size={22} />
                </button>
                <h1 className="text-xl font-bold tracking-wide mr-2">الإعدادات</h1>
              </div>

              <div className="flex-1 overflow-y-auto p-5">
                <h2 className="text-lg font-bold text-gray-800 mb-2">إعدادات مزود الخدمة (Groq API)</h2>
                <p className="text-sm text-gray-500 mb-6">أدخل مفتاح Groq API الخاص بك للبدء في تفريغ الصوتيات عبر نموذج Whisper.</p>

                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-400">
                      <Key size={18} />
                    </div>
                    <input 
                      type="password" 
                      value={apiKey}
                      onChange={(e) => setApiKey(e.target.value)}
                      className="w-full pl-3 pr-10 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all text-left font-mono"
                      placeholder="gsk_..."
                      dir="ltr"
                    />
                  </div>
                </div>

                {apikeyTestResult && (
                  <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className={`p-3 rounded-xl mb-4 flex items-center gap-3 border ${apikeyTestResult.success ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'}`}
                  >
                    {apikeyTestResult.success ? (
                      <CheckCircle2 className="text-green-600 shrink-0" size={20} />
                    ) : (
                      <AlertCircle className="text-red-600 shrink-0" size={20} />
                    )}
                    <span className={`text-sm font-medium ${apikeyTestResult.success ? 'text-green-800' : 'text-red-800'}`}>
                      {apikeyTestResult.msg}
                    </span>
                  </motion.div>
                )}

                <div className="flex gap-3 mt-6">
                  <button 
                    onClick={handleTestKey}
                    disabled={isTestingApiKey}
                    className="flex-1 bg-white border border-gray-300 text-gray-700 rounded-xl py-3 px-4 font-bold flex items-center justify-center gap-2 hover:bg-gray-50 active:scale-95 transition-all outline-none"
                  >
                    {isTestingApiKey ? (
                       <div className="w-5 h-5 border-2 border-gray-400 border-t-transparent rounded-full animate-spin" />
                    ) : (
                       <Wifi size={18} />
                    )}
                    اختبار الاتصال
                  </button>
                  <button 
                    onClick={saveSettings}
                    disabled={isTestingApiKey}
                    className="flex-1 bg-blue-600 text-white rounded-xl py-3 px-4 font-bold flex items-center justify-center gap-2 hover:bg-blue-700 active:scale-95 transition-all shadow-md shadow-blue-200 outline-none"
                  >
                    <Save size={18} />
                    حفظ
                  </button>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Results Overlay */}
        <AnimatePresence>
          {showResults && (
            <motion.div 
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="absolute inset-0 z-50 bg-white flex flex-col"
            >
              <div className="bg-blue-600 text-white px-4 py-4 flex items-center justify-between shadow-md">
                <div className="flex items-center">
                  <button 
                    className="p-2 rounded-full hover:bg-white/10 transition-colors"
                    onClick={() => setShowResults(false)}
                  >
                    <X size={22} />
                  </button>
                  <h1 className="text-xl font-bold tracking-wide mr-2">النتائج</h1>
                </div>
                <div className="flex gap-2">
                  <button className="p-2 rounded-full hover:bg-white/10 transition-colors">
                    <Share2 size={20} />
                  </button>
                  <button className="p-2 rounded-full hover:bg-white/10 transition-colors">
                    <Copy size={20} />
                  </button>
                </div>
              </div>

              {/* Stats & Tools */}
              <div className="bg-blue-50/30 p-4 border-b border-gray-100 flex flex-col gap-4 shadow-sm z-10">
                <div className="flex justify-around items-center">
                  <div className="text-center flex-1">
                    <span className="block text-2xl font-bold text-blue-600">{finalText.split(/\s+/).filter(w => w.length > 0).length}</span>
                    <span className="text-xs text-gray-500 font-medium">الكلمات</span>
                  </div>
                  <div className="w-px h-8 bg-gray-200"></div>
                  <div className="text-center flex-1">
                    <span className="block text-2xl font-bold text-blue-600">{finalText.length}</span>
                    <span className="text-xs text-gray-500 font-medium">الأحرف</span>
                  </div>
                </div>

                <div className="flex gap-3">
                  <button className="flex-1 bg-white border border-gray-300 text-gray-700 rounded-xl py-2 px-3 text-sm font-bold flex items-center justify-center gap-2 hover:bg-gray-50 active:scale-95 transition-all outline-none shadow-sm">
                    <FileText size={16} className="text-red-500" />
                    حفظ PDF
                  </button>
                  <button className="flex-1 bg-white border border-gray-300 text-gray-700 rounded-xl py-2 px-3 text-sm font-bold flex items-center justify-center gap-2 hover:bg-gray-50 active:scale-95 transition-all outline-none shadow-sm">
                    <FileText size={16} className="text-blue-500" />
                    حفظ TXT
                  </button>
                </div>

                <div className="relative">
                  <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-400">
                    <Search size={16} />
                  </div>
                  <input 
                    type="text" 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-10 py-2.5 bg-white border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all text-sm"
                    placeholder="البحث داخل النص..."
                  />
                  {searchQuery && (
                    <button 
                      onClick={() => setSearchQuery("")}
                      className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400 hover:text-gray-600"
                    >
                      <X size={16} />
                    </button>
                  )}
                </div>
              </div>

              {/* Text Body */}
              <div className="flex-1 overflow-y-auto p-5 bg-white">
                 <div className="bg-gray-50 border border-gray-100 rounded-2xl p-5 min-h-full leading-loose text-gray-800 text-lg" dir="rtl">
                   {searchQuery ? (
                     <HighlightText text={finalText} query={searchQuery} />
                   ) : (
                     finalText.split('\n').map((line, i) => <p key={i} className="mb-4">{line}</p>)
                   )}
                 </div>
              </div>

            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function HighlightText({ text, query }: { text: string, query: string }) {
  if (!query) return <>{text}</>;

  const parts = text.split(new RegExp(`(${query})`, 'gi'));

  return (
    <p>
      {parts.map((part, index) => 
        part.toLowerCase() === query.toLowerCase() ? (
          <span key={index} className="bg-yellow-300 text-black font-bold rounded-sm px-1 py-0.5">{part}</span>
        ) : (
          <span key={index}>{part}</span>
        )
      )}
    </p>
  );
}
