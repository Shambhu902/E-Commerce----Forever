import React, { useContext } from "react";
import { ShopContext } from "../contexts/ShopContext";
import { Link } from "react-router-dom";


const ProductItem = ({ id, image, name, price }) => {
  const { currency } = useContext(ShopContext);
  // Debug: log the image prop
  console.log('ProductItem image prop:', image);

  // Handle both array and string cases
  let imgSrc = '';
  if (Array.isArray(image)) {
    imgSrc = image[0];
  } else if (typeof image === 'string') {
    imgSrc = image;
  }

  return (
    <Link className="text-gray-700 cursor-pointer" to={`/product/${id}`}>
      <div className="overflow-hidden">
        <img
          className="hover:scale-110 transition ease-in-out"
          src={imgSrc}
          alt="product_image"
        />
      </div>
      <p className="pt-3 pb-1 text-sm">{name}</p>
      <p className="text-sm font-medium">
        {currency}
        {price}
      </p>
    </Link>
  );
};

export default ProductItem;