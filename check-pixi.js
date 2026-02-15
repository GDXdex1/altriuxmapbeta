
try {
    const PixiReact = require('@pixi/react');
    console.log('Exports de @pixi/react:', Object.keys(PixiReact));
} catch (e) {
    console.error('Error cargando @pixi/react:', e.message);
}
