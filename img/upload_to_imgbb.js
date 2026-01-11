const fs = require('fs');
const path = require('path');
const FormData = require('form-data');

// Your imgbb API key - get it from https://api.imgbb.com/
const API_KEY = '205a7c56ba1ac6a15ddaaf93539bd061';

// Read the images collection
const imagesCollection = JSON.parse(fs.readFileSync('./images_collection.json', 'utf8'));

// Function to upload a single image to imgbb
async function uploadToImgbb(imagePath, imageName) {
    const absolutePath = path.resolve(imagePath);
    
    if (!fs.existsSync(absolutePath)) {
        console.error(`File not found: ${absolutePath}`);
        return null;
    }

    const imageData = fs.readFileSync(absolutePath);
    const base64Image = imageData.toString('base64');

    const formData = new FormData();
    formData.append('key', API_KEY);
    formData.append('image', base64Image);
    formData.append('name', path.parse(imageName).name);

    try {
        const response = await fetch('https://api.imgbb.com/1/upload', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();
        return result;
    } catch (error) {
        console.error(`Error uploading ${imageName}:`, error.message);
        return { error: error.message, imageName };
    }
}

// Main function to process all images
async function processAllImages() {
    const results = [];
    
    console.log(`Starting upload of ${imagesCollection.length} images to imgbb...\n`);

    for (const img of imagesCollection) {
        const imagePath = img.url.replace('./', './');
        console.log(`Uploading [${img.indexno}/${imagesCollection.length}]: ${img.name}...`);
        
        const response = await uploadToImgbb(imagePath, img.name);
        
        if (response && response.success) {
            console.log(`  ✓ Success: ${response.data.url}`);
            results.push({
                indexno: img.indexno,
                originalName: img.originalName,
                imgbbResponse: response
            });
        } else {
            console.log(`  ✗ Failed: ${response?.error?.message || 'Unknown error'}`);
            results.push({
                indexno: img.indexno,
                originalName: img.originalName,
                imgbbResponse: response,
                error: true
            });
        }

        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 500));
    }

    // Save results to imgs.json
    fs.writeFileSync('./imgs.json', JSON.stringify(results, null, 2), 'utf8');
    console.log(`\n✓ Done! Results saved to imgs.json`);
    
    const successCount = results.filter(r => !r.error).length;
    console.log(`  Successful: ${successCount}/${imagesCollection.length}`);
}

// Run the script
processAllImages().catch(console.error);
