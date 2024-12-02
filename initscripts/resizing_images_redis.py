import os
from pathlib import Path
from PIL import Image
import logging
import sys
from tqdm import tqdm
from typing import Tuple, Optional
import imghdr

class ImageProcessor:
    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        # Menținem o dimensiune rezonabilă pentru a păstra detaliile
        self.thumbnail_size = (128, 128)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('image_processing.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def optimize_for_web(self, img: Image.Image) -> Image.Image:
        """Optimizează imaginea păstrând calitatea și culorile"""
        # Păstrăm profilul de culoare RGB
        if 'icc_profile' in img.info:
            img = img.convert('RGB')
        
        # Curățăm metadata păstrând calitatea imaginii
        img_clean = Image.new('RGB', img.size)
        img_clean.paste(img)
        return img_clean

    def process_image(self, image_path: Path, exercise_name: str) -> bool:
        try:
            self.logger.info(f"Processing image: {image_path}")
            
            if not imghdr.what(image_path):
                self.logger.error(f"Not a valid image file: {image_path}")
                return False
    
            with Image.open(image_path) as img:
                # Convertim la RGB dacă e necesar
                if img.mode in ('RGBA', 'P', 'CMYK'):
                    img = img.convert('RGB')
                
                # Optimizare păstrând calitatea
                img = self.optimize_for_web(img)
                
                # Redimensionare cu păstrarea proportiilor și calității
                img.thumbnail(self.thumbnail_size, Image.Resampling.LANCZOS)
                
                exercise_output_dir = self.output_dir / exercise_name
                exercise_output_dir.mkdir(parents=True, exist_ok=True)
                output_path = exercise_output_dir / f"{image_path.stem}.jpg"
                
                # Salvare cu setări optimizate dar păstrând calitatea
                img.save(
                    output_path,
                    'JPEG',
                    quality=70,  # Calitate ridicată
                    optimize=True,
                    progressive=True,
                    subsampling='4:2:2',  # Bun compromis între calitate și dimensiune
                    icc_profile=None,  # Eliminăm profilul de culoare pentru dimensiune mai mică
                    exif=b""  # Eliminăm metadata EXIF
                )
                
                if not output_path.exists() or output_path.stat().st_size == 0:
                    raise Exception("Output file is empty or not created")
                
                self.logger.info(f"Successfully processed: {output_path}")
                return True
                
        except Exception as e:
            self.logger.error(f"Error processing {image_path}: {str(e)}")
            return False

    def process_batch(self) -> Tuple[int, int]:
        image_files = []
        for exercise_dir in self.input_dir.iterdir():
            if exercise_dir.is_dir():
                exercise_name = exercise_dir.name
                # Căutăm doar imaginea 0.jpg în fiecare folder
                img_path = exercise_dir / "0.jpg"
                if img_path.exists():
                    image_files.append((img_path, exercise_name))
        
        if not image_files:
            self.logger.warning(f"No images found in {self.input_dir}")
            return 0, 0
        
        total_images = len(image_files)
        self.logger.info(f"Found {total_images} images to process")
        
        successful = 0
        failed = 0
        
        with tqdm(total=total_images, desc="Processing images") as pbar:
            for img_path, exercise_name in image_files:
                if self.process_image(img_path, exercise_name):
                    successful += 1
                else:
                    failed += 1
                pbar.update(1)
        
        return successful, failed

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
    successful, failed = processor.process_batch()
    
    print(f"""
    Processing completed:
    ✓ Successfully processed: {successful}
    ✗ Failed: {failed}
    
    Processed images can be found in: {output_dir}
    """)

if __name__ == "__main__":
    main()