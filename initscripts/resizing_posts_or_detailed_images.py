import os
import sys
from PIL import Image
import concurrent.futures
from pathlib import Path
import logging
from tqdm import tqdm

class ImageProcessor:
    def __init__(self, input_dir, output_dir):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if sys.platform.startswith('win'):
            sys.stdout.reconfigure(encoding='utf-8')
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('image_processing.log', encoding='utf-8'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def optimize_image(self, img):
        """Optimize image while maintaining original dimensions and quality."""
        if img.mode in ('RGBA', 'P'):
            img = img.convert('RGB')
        return img

    def process_single_image(self, image_path, exercise_name):
        try:
            self.logger.info(f"Processing image: {image_path}")
            
            with Image.open(image_path) as img:
                original_size = os.path.getsize(image_path)
                processed_img = self.optimize_image(img)
                
                exercise_output_dir = self.output_dir / exercise_name
                exercise_output_dir.mkdir(parents=True, exist_ok=True)
                
                output_path = exercise_output_dir / f"{image_path.stem}.webp"
                
                # Start with high quality and gradually decrease if needed
                quality = 95
                min_quality = 75
                target_ratio = 0.7  # Try to achieve at least 30% reduction
                
                while quality >= min_quality:
                    processed_img.save(
                        output_path,
                        'WEBP',
                        quality=quality,
                        method=6,  # Highest compression effort
                        lossless=False,
                        exact=True
                    )
                    
                    new_size = os.path.getsize(output_path)
                    compression_ratio = new_size / original_size
                    
                    # If we achieve good compression or hit minimum quality, stop
                    if compression_ratio <= target_ratio or quality == min_quality:
                        break
                    
                    # Decrease quality more aggressively if we're far from target
                    if compression_ratio > 0.9:
                        quality -= 5
                    else:
                        quality -= 2
                
                compression_percentage = (1 - new_size / original_size) * 100
                
                self.logger.info(f"""
                Successfully processed: {output_path}
                Original size: {original_size/1024:.1f}KB
                New size: {new_size/1024:.1f}KB
                Compression: {compression_percentage:.1f}%
                Final quality: {quality}
                Original dimensions: {img.size}
                """)
                
                return True, image_path.name, original_size, new_size
                
        except Exception as e:
            self.logger.error(f"Error processing {image_path}: {str(e)}")
            return False, image_path.name, 0, 0

    def find_images(self):
        """Find all images in subdirectories."""
        image_files = []
        exercise_dirs = [d for d in self.input_dir.iterdir() if d.is_dir()]
        
        self.logger.info(f"Found {len(exercise_dirs)} exercise directories")
        
        for exercise_dir in exercise_dirs:
            exercise_name = exercise_dir.name
            for img_num in ['0.jpg', '1.jpg']:
                img_path = exercise_dir / img_num
                if img_path.exists():
                    image_files.append((img_path, exercise_name))
        
        return image_files

    def process_batch(self, max_workers=None):
        image_files = self.find_images()
        
        if not image_files:
            self.logger.warning(f"No images found in {self.input_dir}")
            print(f"No images found in {self.input_dir}")
            return 0, 0, 0, 0
        
        total_images = len(image_files)
        self.logger.info(f"Found {total_images} images to process")
        print(f"Found {total_images} images to process")
        
        successful = 0
        failed = 0
        total_original_size = 0
        total_compressed_size = 0
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {executor.submit(self.process_single_image, img_path, exercise_name): img_path 
                      for img_path, exercise_name in image_files}
            
            with tqdm(total=total_images, desc="Processing images") as pbar:
                for future in concurrent.futures.as_completed(futures):
                    result = future.result()
                    success, filename, orig_size, new_size = result
                    if success:
                        successful += 1
                        total_original_size += orig_size
                        total_compressed_size += new_size
                    else:
                        failed += 1
                    pbar.update(1)
        
        return successful, failed, total_original_size, total_compressed_size

def main():
    script_dir = Path(__file__).parent
    input_dir = script_dir / "exercises"
    output_dir = script_dir / "processed_exercises"
    
    print(f"Input directory: {input_dir}")
    print(f"Output directory: {output_dir}")
    
    if not input_dir.exists():
        print(f"ERROR: Input directory does not exist: {input_dir}")
        return
    
    processor = ImageProcessor(input_dir, output_dir)
    successful, failed, total_original_size, total_compressed_size = processor.process_batch()
    
    total_compression_ratio = (1 - total_compressed_size / total_original_size) * 100 if total_original_size > 0 else 0
    
    print(f"""
    Processing completed:
    ✓ Successfully processed: {successful}
    ✗ Failed: {failed}
    
    Total compression results:
    • Original size: {total_original_size/1024/1024:.1f}MB
    • Compressed size: {total_compressed_size/1024/1024:.1f}MB
    • Total space saved: {(total_original_size - total_compressed_size)/1024/1024:.1f}MB
    • Average compression ratio: {total_compression_ratio:.1f}%
    
    Processed images can be found in: {output_dir}
    """)

if __name__ == "__main__":
    main()