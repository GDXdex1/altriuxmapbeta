import React, { useState, useRef, useCallback } from 'react';
import type { CoatOfArms } from '@/types/heraldry';
import { 
  DEFAULT_COAT_OF_ARMS, 
  SHIELD_SHAPES, 
  HELM_TYPES, 
  CREST_TYPES, 
  MANTLING_TYPES, 
  SUPPORTER_TYPES, 
  FIELD_PATTERNS,
  MOTTO_STYLES,
  CENTRAL_CHARGES,
  UPPER_CHARGES,
  LOWER_CHARGES,
  CROSSED_BACKGROUNDS,
  exportShieldForGame,
} from '@/types/heraldry';
import { CoatOfArmsSVG } from './CoatOfArmsSVG';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Slider } from '@/components/ui/slider';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { toast } from 'sonner';
import { 
  Shield, 
  Crown, 
  Swords, 
  Scroll, 
  Layers,
  Download,
  Save,
  RotateCcw
} from 'lucide-react';

interface CoatOfArmsEditorProps {
  initialCoatOfArms?: CoatOfArms;
  onSave?: (coatOfArms: CoatOfArms) => void;
}

export const CoatOfArmsEditor: React.FC<CoatOfArmsEditorProps> = ({
  initialCoatOfArms = DEFAULT_COAT_OF_ARMS,
  onSave,
}) => {
  const [coatOfArms, setCoatOfArms] = useState<CoatOfArms>(initialCoatOfArms);
  const [activeTab, setActiveTab] = useState('shield');
  const svgRef = useRef<SVGSVGElement>(null);

  const updateCoatOfArms = useCallback((path: string, value: any) => {
    setCoatOfArms((prev) => {
      const newCoatOfArms = { ...prev };
      const keys = path.split('.');
      let current: any = newCoatOfArms;
      
      for (let i = 0; i < keys.length - 1; i++) {
        current[keys[i]] = { ...current[keys[i]] };
        current = current[keys[i]];
      }
      
      current[keys[keys.length - 1]] = value;
      return newCoatOfArms;
    });
  }, []);

  const handleExportPNG = useCallback(async () => {
    if (!svgRef.current) {
      toast.error('SVG element not found');
      return;
    }

    try {
      const svgElement = svgRef.current;
      const svgData = new XMLSerializer().serializeToString(svgElement);
      
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        toast.error('Could not create canvas context');
        return;
      }

      canvas.width = 800;
      canvas.height = 1000;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const img = new Image();
      const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
      const url = URL.createObjectURL(svgBlob);

      img.onload = () => {
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        URL.revokeObjectURL(url);

        const pngUrl = canvas.toDataURL('image/png');
        const downloadLink = document.createElement('a');
        downloadLink.href = pngUrl;
        downloadLink.download = `altriux_shield_${Date.now()}.png`;
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

        // Export for game integration
        const gameExport = exportShieldForGame(coatOfArms, pngUrl);
        console.log('Shield exported for game:', gameExport);

        toast.success('Shield exported successfully!');
      };

      img.src = url;
    } catch (error) {
      console.error('Export error:', error);
      toast.error('Error exporting shield');
    }
  }, [coatOfArms]);

  const handleRegister = useCallback(() => {
    if (onSave) {
      onSave(coatOfArms);
    }
    toast.success('Shield registered! Cost: 10 AGC');
  }, [coatOfArms, onSave]);

  const handleReset = useCallback(() => {
    setCoatOfArms(DEFAULT_COAT_OF_ARMS);
    toast.info('Reset to default');
  }, []);

  return (
    <div className="flex flex-col xl:flex-row gap-6 p-4">
      {/* Preview Panel */}
      <div className="xl:w-5/12 flex flex-col items-center">
        <Card className="w-full bg-gradient-to-br from-gray-900 to-black border-orange-500/30">
          <CardHeader className="border-b border-orange-500/20">
            <CardTitle className="text-center text-orange-400 flex items-center justify-center gap-2">
              <Shield className="w-6 h-6" />
              Shield Preview
            </CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center pt-6">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 shadow-2xl border border-orange-500/20">
              <CoatOfArmsSVG
                ref={svgRef}
                coatOfArms={coatOfArms}
                width={320}
                height={400}
              />
            </div>
            
            <div className="flex flex-wrap gap-3 mt-6 justify-center">
              <Button 
                onClick={handleRegister} 
                className="bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white font-bold px-6"
              >
                <Save className="w-4 h-4 mr-2" />
                Register Shield (10 AGC)
              </Button>
              <Button 
                onClick={handleExportPNG} 
                variant="outline"
                className="border-orange-500/50 text-orange-400 hover:bg-orange-500/10"
              >
                <Download className="w-4 h-4 mr-2" />
                Export PNG
              </Button>
              <Button 
                onClick={handleReset}
                variant="outline"
                className="border-gray-600 text-gray-400 hover:bg-gray-800"
              >
                <RotateCcw className="w-4 h-4 mr-2" />
                Reset
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Editor Panel */}
      <div className="xl:w-7/12">
        <Card className="w-full bg-gradient-to-br from-gray-900 to-black border-orange-500/30">
          <CardHeader className="border-b border-orange-500/20">
            <CardTitle className="text-orange-400 flex items-center gap-2">
              <Layers className="w-5 h-5" />
              Shield Editor
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4">
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className="grid grid-cols-5 bg-gray-800/50 mb-4">
                <TabsTrigger value="shield" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
                  <Shield className="w-4 h-4 mr-1" />
                  Shield
                </TabsTrigger>
                <TabsTrigger value="helm" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
                  <Crown className="w-4 h-4 mr-1" />
                  Helm
                </TabsTrigger>
                <TabsTrigger value="charges" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
                  <Swords className="w-4 h-4 mr-1" />
                  Charges
                </TabsTrigger>
                <TabsTrigger value="supporters" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
                  <Layers className="w-4 h-4 mr-1" />
                  Supporters
                </TabsTrigger>
                <TabsTrigger value="motto" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
                  <Scroll className="w-4 h-4 mr-1" />
                  Motto
                </TabsTrigger>
              </TabsList>

              {/* Shield Tab */}
              <TabsContent value="shield" className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Shield Shape</Label>
                    <Select
                      value={coatOfArms.shield.shape}
                      onValueChange={(value) => updateCoatOfArms('shield.shape', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30">
                        {SHIELD_SHAPES.map((shape) => (
                          <SelectItem key={shape.value} value={shape.value} className="text-gray-200">
                            {shape.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label className="text-orange-300">Field Pattern</Label>
                    <Select
                      value={coatOfArms.shield.fieldPattern}
                      onValueChange={(value) => updateCoatOfArms('shield.fieldPattern', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30">
                        {FIELD_PATTERNS.map((pattern) => (
                          <SelectItem key={pattern.value} value={pattern.value} className="text-gray-200">
                            {pattern.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Primary Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.shield.fieldColor}
                        onChange={(e) => updateCoatOfArms('shield.fieldColor', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.shield.fieldColor}
                        onChange={(e) => updateCoatOfArms('shield.fieldColor', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>

                  {coatOfArms.shield.fieldPattern !== 'solid' && (
                    <div className="space-y-2">
                      <Label className="text-orange-300">Secondary Color</Label>
                      <div className="flex gap-2">
                        <Input
                          type="color"
                          value={coatOfArms.shield.secondaryColor}
                          onChange={(e) => updateCoatOfArms('shield.secondaryColor', e.target.value)}
                          className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                        />
                        <Input
                          type="text"
                          value={coatOfArms.shield.secondaryColor}
                          onChange={(e) => updateCoatOfArms('shield.secondaryColor', e.target.value)}
                          className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                        />
                      </div>
                    </div>
                  )}
                </div>

                {/* Border Settings */}
                <div className="border-t border-orange-500/20 pt-4">
                  <h4 className="text-orange-400 font-semibold mb-3">Border Settings</h4>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label className="text-orange-300">Border Color</Label>
                      <div className="flex gap-2">
                        <Input
                          type="color"
                          value={coatOfArms.shield.borderColor}
                          onChange={(e) => updateCoatOfArms('shield.borderColor', e.target.value)}
                          className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                        />
                        <Input
                          type="text"
                          value={coatOfArms.shield.borderColor}
                          onChange={(e) => updateCoatOfArms('shield.borderColor', e.target.value)}
                          className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                        />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <Label className="text-orange-300">Border Width: {coatOfArms.shield.borderWidth}px</Label>
                      <Slider
                        value={[coatOfArms.shield.borderWidth]}
                        onValueChange={([value]) => updateCoatOfArms('shield.borderWidth', value)}
                        min={1}
                        max={10}
                        step={1}
                        className="py-2"
                      />
                    </div>
                  </div>
                </div>
              </TabsContent>

              {/* Helm Tab */}
              <TabsContent value="helm" className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Helm Type</Label>
                    <Select
                      value={coatOfArms.helm.type}
                      onValueChange={(value) => updateCoatOfArms('helm.type', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30">
                        {HELM_TYPES.map((helm) => (
                          <SelectItem key={helm.value} value={helm.value} className="text-gray-200">
                            {helm.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label className="text-orange-300">Helm Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.helm.color}
                        onChange={(e) => updateCoatOfArms('helm.color', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.helm.color}
                        onChange={(e) => updateCoatOfArms('helm.color', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Crest Type</Label>
                    <Select
                      value={coatOfArms.crest.type}
                      onValueChange={(value) => updateCoatOfArms('crest.type', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30">
                        {CREST_TYPES.map((crest) => (
                          <SelectItem key={crest.value} value={crest.value} className="text-gray-200">
                            {crest.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label className="text-orange-300">Crest Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.crest.color}
                        onChange={(e) => updateCoatOfArms('crest.color', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.crest.color}
                        onChange={(e) => updateCoatOfArms('crest.color', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Mantling Type</Label>
                    <Select
                      value={coatOfArms.mantling.type}
                      onValueChange={(value) => updateCoatOfArms('mantling.type', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30">
                        {MANTLING_TYPES.map((mantling) => (
                          <SelectItem key={mantling.value} value={mantling.value} className="text-gray-200">
                            {mantling.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                {coatOfArms.mantling.type !== 'none' && (
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label className="text-orange-300">Mantling Primary</Label>
                      <Input
                        type="color"
                        value={coatOfArms.mantling.primaryColor}
                        onChange={(e) => updateCoatOfArms('mantling.primaryColor', e.target.value)}
                        className="w-full h-10 bg-gray-800 border-orange-500/30"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label className="text-orange-300">Mantling Secondary</Label>
                      <Input
                        type="color"
                        value={coatOfArms.mantling.secondaryColor}
                        onChange={(e) => updateCoatOfArms('mantling.secondaryColor', e.target.value)}
                        className="w-full h-10 bg-gray-800 border-orange-500/30"
                      />
                    </div>
                  </div>
                )}
              </TabsContent>

              {/* Charges Tab */}
              <TabsContent value="charges" className="space-y-4">
                <ScrollArea className="h-[350px]">
                  <div className="space-y-4 pr-4">
                    {/* Central Charge */}
                    <div className="space-y-2">
                      <Label className="text-orange-300 font-semibold">Central Charge (Main Symbol)</Label>
                      <div className="grid grid-cols-3 gap-2">
                        {Object.entries(CENTRAL_CHARGES).map(([category, charges]) => (
                          <div key={category} className="col-span-3">
                            <p className="text-xs text-orange-400/70 mb-1">{category}</p>
                            <div className="grid grid-cols-3 gap-1">
                              {charges.map((charge) => (
                                <Button
                                  key={charge.value}
                                  variant={coatOfArms.centralCharge.type === charge.value ? 'default' : 'outline'}
                                  onClick={() => updateCoatOfArms('centralCharge.type', charge.value)}
                                  className={`text-xs h-8 ${
                                    coatOfArms.centralCharge.type === charge.value 
                                      ? 'bg-orange-500 hover:bg-orange-600' 
                                      : 'border-orange-500/30 text-gray-300 hover:bg-orange-500/10'
                                  }`}
                                  size="sm"
                                >
                                  {charge.label}
                                </Button>
                              ))}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {coatOfArms.centralCharge.type !== 'none' && (
                      <>
                        <div className="space-y-2">
                          <Label className="text-orange-300">Central Charge Color</Label>
                          <Input
                            type="color"
                            value={coatOfArms.centralCharge.color}
                            onChange={(e) => updateCoatOfArms('centralCharge.color', e.target.value)}
                            className="w-full h-10 bg-gray-800 border-orange-500/30"
                          />
                        </div>
                        <div className="space-y-2">
                          <Label className="text-orange-300">Position X: {coatOfArms.centralCharge.position.x}%</Label>
                          <Slider
                            value={[coatOfArms.centralCharge.position.x]}
                            onValueChange={([value]) => updateCoatOfArms('centralCharge.position.x', value)}
                            min={20}
                            max={80}
                            step={1}
                            className="py-2"
                          />
                        </div>
                        <div className="space-y-2">
                          <Label className="text-orange-300">Position Y: {coatOfArms.centralCharge.position.y}%</Label>
                          <Slider
                            value={[coatOfArms.centralCharge.position.y]}
                            onValueChange={([value]) => updateCoatOfArms('centralCharge.position.y', value)}
                            min={30}
                            max={70}
                            step={1}
                            className="py-2"
                          />
                        </div>
                        <div className="space-y-2">
                          <Label className="text-orange-300">Scale: {coatOfArms.centralCharge.scale.toFixed(1)}x</Label>
                          <Slider
                            value={[coatOfArms.centralCharge.scale]}
                            onValueChange={([value]) => updateCoatOfArms('centralCharge.scale', value)}
                            min={0.5}
                            max={1.5}
                            step={0.1}
                            className="py-2"
                          />
                        </div>
                      </>
                    )}

                    {/* Upper Charge */}
                    <div className="space-y-2 pt-4 border-t border-orange-500/20">
                      <Label className="text-orange-300 font-semibold">Upper Charge (Above Center)</Label>
                      <Select
                        value={coatOfArms.upperCharge.type}
                        onValueChange={(value) => updateCoatOfArms('upperCharge.type', value)}
                      >
                        <SelectTrigger className="bg-gray-800 border-orange-500/30">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-gray-800 border-orange-500/30">
                          {UPPER_CHARGES.map((charge) => (
                            <SelectItem key={charge.value} value={charge.value} className="text-gray-200">
                              {charge.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {coatOfArms.upperCharge.type !== 'none' && (
                        <div className="space-y-2">
                          <Label className="text-orange-300">Scale: {coatOfArms.upperCharge.scale.toFixed(1)}x</Label>
                          <Slider
                            value={[coatOfArms.upperCharge.scale]}
                            onValueChange={([value]) => updateCoatOfArms('upperCharge.scale', value)}
                            min={0.5}
                            max={1.2}
                            step={0.1}
                            className="py-2"
                          />
                        </div>
                      )}
                    </div>

                    {/* Lower Charge */}
                    <div className="space-y-2 pt-4 border-t border-orange-500/20">
                      <Label className="text-orange-300 font-semibold">Lower Charge (Below Center)</Label>
                      <Select
                        value={coatOfArms.lowerCharge.type}
                        onValueChange={(value) => updateCoatOfArms('lowerCharge.type', value)}
                      >
                        <SelectTrigger className="bg-gray-800 border-orange-500/30">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-gray-800 border-orange-500/30">
                          {LOWER_CHARGES.map((charge) => (
                            <SelectItem key={charge.value} value={charge.value} className="text-gray-200">
                              {charge.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {coatOfArms.lowerCharge.type !== 'none' && (
                        <div className="space-y-2">
                          <Label className="text-orange-300">Scale: {coatOfArms.lowerCharge.scale.toFixed(1)}x</Label>
                          <Slider
                            value={[coatOfArms.lowerCharge.scale]}
                            onValueChange={([value]) => updateCoatOfArms('lowerCharge.scale', value)}
                            min={0.5}
                            max={1.2}
                            step={0.1}
                            className="py-2"
                          />
                        </div>
                      )}
                    </div>

                    {/* Crossed Background */}
                    <div className="space-y-2 pt-4 border-t border-orange-500/20">
                      <Label className="text-orange-300 font-semibold">Crossed Background</Label>
                      <Select
                        value={coatOfArms.crossedBackground.type}
                        onValueChange={(value) => updateCoatOfArms('crossedBackground.type', value)}
                      >
                        <SelectTrigger className="bg-gray-800 border-orange-500/30">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-gray-800 border-orange-500/30">
                          {CROSSED_BACKGROUNDS.map((bg) => (
                            <SelectItem key={bg.value} value={bg.value} className="text-gray-200">
                              {bg.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {coatOfArms.crossedBackground.type !== 'none' && (
                        <div className="space-y-2">
                          <Label className="text-orange-300">Opacity: {Math.round(coatOfArms.crossedBackground.opacity * 100)}%</Label>
                          <Slider
                            value={[coatOfArms.crossedBackground.opacity]}
                            onValueChange={([value]) => updateCoatOfArms('crossedBackground.opacity', value)}
                            min={0.1}
                            max={0.8}
                            step={0.1}
                            className="py-2"
                          />
                        </div>
                      )}
                    </div>
                  </div>
                </ScrollArea>
              </TabsContent>

              {/* Supporters Tab */}
              <TabsContent value="supporters" className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Left Supporter</Label>
                    <Select
                      value={coatOfArms.supporters.left}
                      onValueChange={(value) => updateCoatOfArms('supporters.left', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30 max-h-64">
                        {SUPPORTER_TYPES.map((supporter) => (
                          <SelectItem key={supporter.value} value={supporter.value} className="text-gray-200">
                            {supporter.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label className="text-orange-300">Right Supporter</Label>
                    <Select
                      value={coatOfArms.supporters.right}
                      onValueChange={(value) => updateCoatOfArms('supporters.right', value)}
                    >
                      <SelectTrigger className="bg-gray-800 border-orange-500/30">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-orange-500/30 max-h-64">
                        {SUPPORTER_TYPES.map((supporter) => (
                          <SelectItem key={supporter.value} value={supporter.value} className="text-gray-200">
                            {supporter.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                {(coatOfArms.supporters.left !== 'none' || coatOfArms.supporters.right !== 'none') && (
                  <div className="space-y-2">
                    <Label className="text-orange-300">Supporter Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.supporters.color}
                        onChange={(e) => updateCoatOfArms('supporters.color', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.supporters.color}
                        onChange={(e) => updateCoatOfArms('supporters.color', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>
                )}
              </TabsContent>

              {/* Motto Tab */}
              <TabsContent value="motto" className="space-y-4">
                <div className="space-y-2">
                  <Label className="text-orange-300">Motto Text</Label>
                  <Input
                    type="text"
                    value={coatOfArms.motto.text}
                    onChange={(e) => updateCoatOfArms('motto.text', e.target.value)}
                    placeholder="Enter your motto..."
                    maxLength={50}
                    className="bg-gray-800 border-orange-500/30 text-gray-200"
                  />
                </div>

                <div className="space-y-2">
                  <Label className="text-orange-300">Motto Style</Label>
                  <Select
                    value={coatOfArms.motto.style}
                    onValueChange={(value) => updateCoatOfArms('motto.style', value)}
                  >
                    <SelectTrigger className="bg-gray-800 border-orange-500/30">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-orange-500/30">
                      {MOTTO_STYLES.map((style) => (
                        <SelectItem key={style.value} value={style.value} className="text-gray-200">
                          {style.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-orange-300">Text Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.motto.color}
                        onChange={(e) => updateCoatOfArms('motto.color', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.motto.color}
                        onChange={(e) => updateCoatOfArms('motto.color', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label className="text-orange-300">Background Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={coatOfArms.motto.backgroundColor}
                        onChange={(e) => updateCoatOfArms('motto.backgroundColor', e.target.value)}
                        className="w-14 h-10 p-1 bg-gray-800 border-orange-500/30"
                      />
                      <Input
                        type="text"
                        value={coatOfArms.motto.backgroundColor}
                        onChange={(e) => updateCoatOfArms('motto.backgroundColor', e.target.value)}
                        className="flex-1 bg-gray-800 border-orange-500/30 text-gray-200"
                      />
                    </div>
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default CoatOfArmsEditor;
