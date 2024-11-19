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
        """Resize image maintaining aspect ratio and add padding matching the original background color."""
        original_width, original_height = img.size
        aspect_ratio = original_width / original_height
        target_width, target_height = target_size
        
        # Calculate new dimensions maintaining aspect ratio
        if aspect_ratio > 1:
            new_width = target_width
            new_height = int(target_width / aspect_ratio)
        else:
            new_height = target_height
            new_width = int(target_height * aspect_ratio)
            
        # Resize the image
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Determine background color from corners of original image
        corners = [
            img.getpixel((0, 0)),
            img.getpixel((0, img.height-1)),
            img.getpixel((img.width-1, 0)),
            img.getpixel((img.width-1, img.height-1))
        ]
        bg_color = max(set(corners), key=corners.count)  # Most common corner color
        
        # Create new background with matched color
        background = Image.new(img.mode, target_size, bg_color)
        
        # Calculate position to paste resized image
        paste_x = (target_width - new_width) // 2
        paste_y = (target_height - new_height) // 2
        
        # Paste resized image onto background
        background.paste(img, (paste_x, paste_y))
        
        return background

    def process_single_image(self, image_path, exercise_name):
        try:
            self.logger.info(f"Processing image: {image_path}")
            
            with Image.open(image_path) as img:
                # Keep original mode (RGB, RGBA, etc.)
                original_mode = img.mode
                original_format = img.format or 'JPEG'  # Default to JPEG if format is None
                
                processed_img = self.smart_resize_with_padding(img, (128, 128))
                
                exercise_output_dir = self.output_dir / exercise_name
                exercise_output_dir.mkdir(parents=True, exist_ok=True)
                
                # Keep original file extension
                output_path = exercise_output_dir / f"{image_path.stem}{image_path.suffix}"
                
                # Save with original format and mode
                save_params = {
                    'format': original_format,
                    'quality': 95  # High quality for all formats that support it
                }
                
                if original_format == 'PNG':
                    save_params['optimize'] = True
                elif original_format == 'JPEG':
                    save_params['optimize'] = True
                    save_params['progressive'] = True
                elif original_format == 'WEBP':
                    save_params['method'] = 6
                    save_params['lossless'] = False
                    save_params['exact'] = True
                
                processed_img.save(output_path, **save_params)
                
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
            for img_path in exercise_dir.glob('*.*'):
                if img_path.suffix.lower() in ['.jpg', '.jpeg', '.png', '.webp']:
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
    output_dir = script_dir / "processed_exercises_128x128"
    
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