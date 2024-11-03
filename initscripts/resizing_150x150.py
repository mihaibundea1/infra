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

    def smart_resize_with_padding(self, img, target_size):
        """Resize image maintaining aspect ratio and add white padding if necessary."""
        original_width, original_height = img.size
        aspect_ratio = original_width / original_height
        target_width, target_height = target_size
        
        # Calculate new dimensions maintaining aspect ratio
        if aspect_ratio > 1:
            # Width is larger
            new_width = target_width
            new_height = int(target_width / aspect_ratio)
        else:
            # Height is larger
            new_height = target_height
            new_width = int(target_height * aspect_ratio)
            
        # Resize the image
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create new white background
        background = Image.new('RGB', target_size, 'white')
        
        # Calculate position to paste resized image
        paste_x = (target_width - new_width) // 2
        paste_y = (target_height - new_height) // 2
        
        # Paste resized image onto white background
        background.paste(img, (paste_x, paste_y))
        
        return background

    def process_single_image(self, image_path, exercise_name):
        try:
            self.logger.info(f"Processing image: {image_path}")
            
            with Image.open(image_path) as img:
                if img.mode in ('RGBA', 'P'):
                    img = img.convert('RGB')
                
                processed_img = self.smart_resize_with_padding(img, (150, 150))
                
                exercise_output_dir = self.output_dir / exercise_name
                exercise_output_dir.mkdir(parents=True, exist_ok=True)
                
                output_path = exercise_output_dir / f"{image_path.stem}.webp"
                processed_img.save(
                    output_path,
                    'WEBP',
                    quality=80,
                    method=6,
                    lossless=False,
                    exact=True
                )
                
                self.logger.info(f"Successfully processed: {output_path}")
                return True, image_path.name
                
        except Exception as e:
            self.logger.error(f"Error processing {image_path}: {str(e)}")
            return False, image_path.name

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
            return 0, 0
        
        total_images = len(image_files)
        self.logger.info(f"Found {total_images} images to process")
        print(f"Found {total_images} images to process")
        
        successful = 0
        failed = 0
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {executor.submit(self.process_single_image, img_path, exercise_name): img_path 
                      for img_path, exercise_name in image_files}
            
            with tqdm(total=total_images, desc="Processing images") as pbar:
                for future in concurrent.futures.as_completed(futures):
                    success, filename = future.result()
                    if success:
                        successful += 1
                    else:
                        failed += 1
                    pbar.update(1)
        
        return successful, failed

def main():
    script_dir = Path(__file__).parent
    input_dir = script_dir / "exercises"
    output_dir = script_dir / "processed_exercises_150x150"
    
    print(f"Input directory: {input_dir}")
    print(f"Output directory: {output_dir}")
    
    if not input_dir.exists():
        print(f"ERROR: Input directory does not exist: {input_dir}")
        return
    
    processor = ImageProcessor(input_dir, output_dir)
    successful, failed = processor.process_batch()
    
    print(f"""
    Processing completed:
    ✓ Successfully processed: {successful}
    ✗ Failed: {failed}
    
    Processed images can be found in: {output_dir}
    """)

if __name__ == "__main__":
    main()